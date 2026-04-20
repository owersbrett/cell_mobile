import 'package:cell_mobile/models/bio_entity.dart';

const multiverseAllEntities = <BioEntity>[
  BioEntity(
    id: 'multiverse_all_mesh',
    scale: BioScale.multiverseAll,
    position: 0,
    name: 'The Mesh of Realities',
    title: 'All Branches, All Histories',
    shortDescription: 'The totality of all quantum branches — an incomprehensibly vast structure where every possible history of every possible particle plays out simultaneously.',
    longDescription:
        'If the Many-Worlds Interpretation is correct, then the multiverse is not a collection of separate, independent universes — it is a single quantum state of unfathomable complexity, a "universal wave function" that encompasses all branches, all histories, all possibilities. Every quantum event since the Big Bang has generated branches, and each branch has generated further branches, creating a tree of exponentially growing complexity.\n\n'
        'The number of branches is not merely astronomical — it exceeds any number that can be meaningfully compared to physical quantities. The number of quantum events in the observable universe since the Big Bang is roughly 10^(10^150), and each event generates at least two branches. The resulting structure — the mesh of all realities — is a mathematical object so vast that it makes the observable universe seem like a single atom by comparison.\n\n'
        'This mesh is not a speculative fantasy; it is the straightforward implication of taking quantum mechanics seriously as a description of reality (rather than merely a calculational tool). The debate is not about whether the math describes this structure — it does — but about whether the math corresponds to physical reality. If it does, then "reality" is not the single, classical universe we perceive but the entire quantum mesh, and our perception of a single classical reality is a consequence of decoherence limiting our experience to one branch.',
    relatedIds: ['multiverse_all_string_landscape', 'multiverse_all_eternal_inflation', 'multiverse_many_worlds'],
  ),
  BioEntity(
    id: 'multiverse_all_string_landscape',
    scale: BioScale.multiverseAll,
    position: 1,
    name: 'String Landscape',
    title: 'The Space of Possible Physics',
    shortDescription: 'String theory predicts 10^500 possible vacuum states, each with different fundamental constants — our universe may be one configuration among an inconceivable number.',
    longDescription:
        'String theory, the leading candidate for a unified theory of quantum gravity, does not predict a single set of physical laws. Instead, it predicts a vast "landscape" of possible vacuum states — an estimated 10^500 different configurations of the extra dimensions required by the theory, each corresponding to a universe with different fundamental constants, different particle masses, different force strengths, and potentially different numbers of spatial dimensions.\n\n'
        'This landscape provides a potential explanation for the fine-tuning problem: if 10^500 different sets of physical laws are all realized somewhere in a multiverse, then it is not surprising that at least some of them permit the existence of complex structures and observers. We find ourselves in a life-permitting universe not because the constants were designed but because, in a vast enough landscape, life-permitting configurations are statistically inevitable. The anthropic principle becomes a selection effect rather than a mystery.\n\n'
        'Critics argue that the string landscape makes string theory unfalsifiable — if any outcome can be accommodated, the theory predicts nothing. Defenders counter that the landscape is a prediction (the existence of many vacua is derived from the theory\'s mathematics, not assumed) and that statistical predictions may still be possible (some configurations may be far more common than others). The string landscape represents the ultimate confrontation between physics and philosophy: is an explanation that invokes 10^500 unobservable universes better or worse than no explanation at all?',
    relatedIds: ['multiverse_all_mesh', 'multiverse_all_eternal_inflation', 'big_questions_fine_tuning'],
  ),
  BioEntity(
    id: 'multiverse_all_eternal_inflation',
    scale: BioScale.multiverseAll,
    position: 2,
    name: 'Eternal Inflation',
    title: 'Universes Spawning Universes',
    shortDescription: 'The inflationary field that drove our universe\'s early expansion may still be inflating elsewhere, continuously spawning new "bubble universes" with different physical laws.',
    longDescription:
        'Cosmic inflation — the theory that the universe underwent a period of exponential expansion in its first 10^-36 to 10^-32 seconds — is well-supported by observations (the flatness, uniformity, and perturbation spectrum of the CMB). But most models of inflation have a startling consequence: inflation, once started, never completely stops. While inflation ended in our region (allowing matter, stars, and galaxies to form), it continues in other regions, and the inflating space expands faster than the regions where inflation ends.\n\n'
        'This "eternal inflation" produces an ever-growing fractal structure of "pocket universes" or "bubble universes," each one nucleating as a region where inflation locally ends. Our observable universe is one such bubble. Each bubble may have different physical constants, determined by the specific way inflation ended in that region (connecting to the string landscape). The total structure — an eternally inflating space studded with bubble universes — is infinite in extent and will produce an infinite number of bubbles over infinite time.\n\n'
        'Eternal inflation transforms cosmology from the study of one universe to the study of an infinite ensemble. It provides the physical mechanism by which the string landscape\'s many vacua could be realized: each bubble universe settles into a different vacuum state with different physics. This is the most concrete and widely discussed mechanism for generating a true multiverse — not a philosophical concept but a physical prediction of our best theories of the early universe.',
    relatedIds: ['multiverse_all_mesh', 'multiverse_all_string_landscape', 'universe_expansion', 'cosmic_cmb'],
  ),
];
