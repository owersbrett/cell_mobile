import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Cell → Neurobiology. The flagship module: the cells that think.
/// Ten entities, position 0..9. Every entity carries moduleId
/// 'cell_neurobiology' and a HOOK + table + fact + thinkReveal.
const List<BioEntity> cellNeurobiologyEntities = <BioEntity>[
  // 0 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_neuron',
    scale: BioScale.cell,
    position: 0,
    name: 'The Neuron',
    title: 'The Cell That Thinks',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'A single cell, shaped like a tree with a tail, that turns a whisper of chemistry into a signal that can travel a meter in a blink.',
    longDescription:
        'A neuron is a cell that specialized in one job: carry a message. It has bushy dendrites that listen, a cell body (soma) that adds up what it hears, a long thin axon that shouts the answer, and axon terminals that hand the message to the next cell.\n\n'
        'You have roughly 86 billion of them. String them together and you get every thought, memory, itch, and idea you have ever had. This whole module is one kind of cell learning to think about itself.',
    relatedIds: ['neuro_synapse', 'neuro_action_potential'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Everything you are — this sentence landing in your head right now — is a wave of salt ions crossing 86 billion tiny membranes. How does a lump of fat and water end up wondering how it works? Start with one cell.',
      ),
      LessonSection.table(
        title: 'The Four Parts of a Neuron',
        headers: ['Part', 'Job', 'Analogy'],
        rows: [
          ['Dendrites', 'Receive incoming signals', 'The ears / inbox'],
          ['Soma (cell body)', 'Sums inputs, holds the nucleus', 'The desk / adder'],
          ['Axon', 'Carries the outgoing spike', 'The cable'],
          ['Axon terminals', 'Pass the signal to the next cell', 'The mailbox'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark Number',
        body:
            '~86 billion neurons in the human brain — and a roughly comparable number of glial support cells alongside them.',
      ),
      LessonSection.thinkReveal(
        title: 'Direction of Flow',
        question:
            'Signals normally travel in ONE direction through a neuron. Which way — dendrites-to-axon, or axon-to-dendrites?',
        answer:
            'Dendrites → soma → axon → terminals. The neuron listens with its dendrites and speaks with its axon terminals. That one-way flow is what lets billions of neurons wire into circuits instead of a screaming feedback loop.',
      ),
    ],
  ),

  // 1 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_resting_potential',
    scale: BioScale.cell,
    position: 1,
    name: 'The Resting Membrane Potential',
    title: 'The −70 mV Battery',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'Every neuron sits charged like a tiny battery at about −70 millivolts, quietly burning fuel to stay ready to fire.',
    longDescription:
        'At rest, the inside of a neuron is about −70 mV negative relative to the outside. This is not an accident — the cell spends real energy to maintain it. The Na⁺/K⁺-ATPase pump grinds constantly, pushing 3 sodium ions (Na⁺) OUT for every 2 potassium ions (K⁺) it lets IN, burning one ATP each cycle.\n\n'
        'That imbalance stores potential energy, exactly like a charged battery. A neuron at rest is a loaded spring — poised, expensive, and ready to snap into an action potential the instant it is pushed past threshold.',
    relatedIds: ['neuro_action_potential', 'neuro_neuron'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'A neuron does nothing at rest — yet resting is the most expensive thing it does. Up to a fifth of the energy your brain burns goes to holding a −70 mV charge on cells that aren\'t even firing. Why pay to sit still? Because you can only fire fast if you\'re pre-loaded.',
      ),
      LessonSection.table(
        title: 'Ion Distribution at Rest',
        headers: ['Ion', 'Concentrated', 'Role'],
        rows: [
          ['Na⁺ (sodium)', 'Outside the cell', 'Rushes IN to fire the spike'],
          ['K⁺ (potassium)', 'Inside the cell', 'Leaks OUT, sets the rest voltage'],
          ['Cl⁻ (chloride)', 'Outside the cell', 'Inhibitory drift'],
          ['A⁻ (big anions)', 'Inside (trapped)', 'Keeps the inside negative'],
        ],
      ),
      LessonSection.fact(
        title: 'The Pump',
        body:
            'Na⁺/K⁺-ATPase: 3 Na⁺ out / 2 K⁺ in per ATP. Net one positive charge exported each cycle — the engine behind the ≈ −70 mV rest.',
      ),
      LessonSection.thinkReveal(
        title: 'Kill the Pump',
        question:
            'If you poisoned the Na⁺/K⁺ pump so it stopped, what happens to the −70 mV resting potential?',
        answer:
            'The gradients slowly collapse. Na⁺ leaks in, K⁺ leaks out, the voltage drifts toward zero, and the neuron can no longer fire clean spikes. The battery isn\'t stored once — it must be actively re-charged forever. Stop paying, and the thinking stops.',
      ),
    ],
  ),

  // 2 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_action_potential',
    scale: BioScale.cell,
    position: 2,
    name: 'The Action Potential',
    title: 'The All-Or-Nothing Spike',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'Push a neuron past about −55 mV and it explodes to +40 mV and back in a millisecond — a spike that either happens completely or not at all.',
    longDescription:
        'The action potential is the neuron\'s only word, and it has no volume knob. When inputs drag the membrane up to the threshold of about −55 mV, voltage-gated Na⁺ channels fly open. Sodium floods in and the voltage rockets from −70 mV up to roughly +40 mV — depolarization. Then Na⁺ channels slam shut, K⁺ channels open, potassium pours out, and the voltage plunges back down — repolarization — briefly overshooting before settling at rest.\n\n'
        'The magic word is all-or-nothing. A bigger stimulus does not make a bigger spike; it makes MORE spikes. And because the spike regenerates itself all the way down the axon, it arrives at the far end just as strong as it left — it travels without decrement.',
    relatedIds: ['neuro_resting_potential', 'neuro_myelin', 'neuro_synapse'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'A −70 mV battery that flips to +40 mV and back in a single millisecond — 110 millivolts of swing, thousands of times a second, in a cell thinner than a hair. How does a neuron fire? By briefly letting the ocean of sodium outside come crashing in, then throwing it back out.',
      ),
      LessonSection.table(
        title: 'The Spike, Phase by Phase',
        headers: ['Phase', 'Voltage', 'What Opens'],
        rows: [
          ['Rest', '≈ −70 mV', 'Nothing — pump holds the line'],
          ['Threshold', '≈ −55 mV', 'Trigger point — no turning back'],
          ['Depolarization', '→ ≈ +40 mV', 'Voltage-gated Na⁺ channels (in)'],
          ['Repolarization', '→ back down', 'Voltage-gated K⁺ channels (out)'],
          ['Refractory dip', 'Brief overshoot', 'Na⁺ channels reset'],
        ],
      ),
      LessonSection.fact(
        title: 'The Rule',
        body:
            'ALL-OR-NOTHING. Threshold ≈ −55 mV, peak ≈ +40 mV. Below threshold: nothing. At or above: a full, identical spike that propagates WITHOUT decrement.',
      ),
      LessonSection.thinkReveal(
        title: 'Loud vs Soft',
        question:
            'A gentle touch and a hard pinch both use action potentials that are the same size. So how does your brain tell soft from painful?',
        answer:
            'By FREQUENCY and RECRUITMENT, not amplitude. A hard pinch fires the same-sized spikes but many more per second, across many more neurons. Intensity is coded in how often and how many fire — never in how big each spike is.',
      ),
    ],
  ),

  // 3 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_synapse',
    scale: BioScale.cell,
    position: 3,
    name: 'The Synapse',
    title: 'The Gap Where Meaning Is Handed Off',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'Two neurons almost never touch — the signal leaps a 20-nanometer gap by converting electricity into a puff of chemical, then back again.',
    longDescription:
        'A synapse is the junction where one neuron passes its message to the next. Crucially, they don\'t touch: a tiny gap called the synaptic cleft (about 20 nanometers) separates them. When an action potential reaches the axon terminal, voltage-gated Ca²⁺ channels open, calcium rushes in, and tiny sacs (vesicles) dump neurotransmitter into the cleft.\n\n'
        'Those molecules drift across and dock onto receptors on the next neuron\'s dendrites, nudging it toward or away from firing its own spike. The electrical signal became chemical to cross the gap, then becomes electrical again. That conversion is where the brain does its arithmetic — and where nearly every drug, from caffeine to antidepressants, does its work.',
    relatedIds: ['neuro_neurotransmitters', 'neuro_action_potential', 'neuro_plasticity'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Your neurons don\'t actually connect. Every thought you\'ve ever had had to leap a gap 20 nanometers wide — a few thousandths the width of a hair — as a chemical mist, trillions of times. The brain is less a wired circuit and more a relay of tiny, deliberate handoffs.',
      ),
      LessonSection.table(
        title: 'Crossing the Cleft — Step by Step',
        headers: ['Step', 'Event'],
        rows: [
          ['1', 'Action potential arrives at the axon terminal'],
          ['2', 'Voltage-gated Ca²⁺ channels open, calcium floods in'],
          ['3', 'Vesicles fuse and release neurotransmitter into the cleft'],
          ['4', 'Neurotransmitter binds receptors on the next neuron'],
          ['5', 'Receiving neuron is nudged toward (or away from) firing'],
          ['6', 'Transmitter is cleared: reuptake, enzymes, or diffusion'],
        ],
      ),
      LessonSection.fact(
        title: 'The Gap',
        body:
            'Synaptic cleft ≈ 20 nanometers. A typical neuron makes thousands of synapses — the human brain holds an estimated 100+ trillion of them.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Go Chemical?',
        question:
            'Electrical signals are fast. Why would evolution add a slow chemical step in the middle of every connection?',
        answer:
            'Control. A chemical gap lets a synapse be strengthened, weakened, silenced, or flipped from excitatory to inhibitory — and lets one signal be turned up or down by drugs and modulators. The gap isn\'t a bug; it\'s the dial. No cleft, no learning.',
      ),
    ],
  ),

  // 4 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_neurotransmitters',
    scale: BioScale.cell,
    position: 4,
    name: 'Neurotransmitters',
    title: 'The Chemical Alphabet',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'A handful of small molecules — glutamate, GABA, dopamine, serotonin, acetylcholine — carry every command, mood, and memory across the gap.',
    longDescription:
        'Neurotransmitters are the molecules a synapse releases. Some are excitatory (they push the next neuron toward firing) and some are inhibitory (they push it away). The two workhorses are glutamate, the brain\'s main EXCITATORY transmitter, and GABA, its main INHIBITORY one. Balance between them is the difference between a calm thought and a seizure.\n\n'
        'Others act as modulators, tuning whole networks: dopamine (motivation, reward, movement), serotonin (mood, sleep, appetite), and acetylcholine (attention, and the command that fires every muscle you move). A molecule isn\'t excitatory or inhibitory by itself — its effect depends on which receptor it hits.',
    relatedIds: ['neuro_synapse', 'neuro_plasticity'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Your mood, your focus, whether your hand moves when you want it to — all of it rides on a few small molecules squirted across a gap. Fewer chemical "letters" than there are letters in the alphabet spell out every state of mind you have. Meet the ones that matter most.',
      ),
      LessonSection.table(
        title: 'The Core Neurotransmitters',
        headers: ['Transmitter', 'Excite / Inhibit', 'Famous For'],
        rows: [
          ['Glutamate', 'Excitatory (main)', 'Learning, most of the "go" in the brain'],
          ['GABA', 'Inhibitory (main)', 'Calm, the brakes; targeted by anti-anxiety drugs'],
          ['Dopamine', 'Modulatory', 'Reward, motivation, movement'],
          ['Serotonin', 'Modulatory', 'Mood, sleep, appetite'],
          ['Acetylcholine', 'Excitatory / mod.', 'Attention; fires every skeletal muscle'],
        ],
      ),
      LessonSection.fact(
        title: 'The Balance',
        body:
            'Glutamate = main EXCITATORY. GABA = main INHIBITORY. Tip that balance too far toward glutamate and neurons fire uncontrollably — that runaway excitation is a seizure.',
      ),
      LessonSection.thinkReveal(
        title: 'Same Molecule, Two Faces',
        question:
            'Acetylcholine speeds up your gut but is also the exact signal that makes your heart beat slower. How can one molecule do opposite things?',
        answer:
            'The RECEPTOR decides, not the molecule. A neurotransmitter is a key; the receptor is the lock, and different tissues install different locks. Same key, different door, opposite result. This is why "is dopamine good or bad?" is the wrong question — it depends entirely on where it lands.',
      ),
    ],
  ),

  // 5 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_myelin',
    scale: BioScale.cell,
    position: 5,
    name: 'Myelin & Saltatory Conduction',
    title: 'Insulation That Speeds Thought',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'Wrap an axon in fatty insulation and the spike stops crawling and starts leaping node to node — up to about 120 meters per second.',
    longDescription:
        'Myelin is a fatty sheath wrapped around many axons like insulation on a wire. It doesn\'t just protect — it transforms speed. Between wrapped segments lie tiny bare gaps called nodes of Ranvier, and this is where the trick lives: the action potential can\'t fire under the insulation, so it JUMPS from node to node instead of creeping continuously along the membrane. This leaping is called saltatory conduction (from the Latin saltare, "to jump").\n\n'
        'The payoff is enormous. A bare (unmyelinated) axon might conduct at a walking pace; a thick myelinated one can carry a signal at up to ~120 meters per second. Faster thought is, quite literally, better insulation.',
    relatedIds: ['neuro_action_potential', 'neuro_oligodendrocytes', 'neuro_astrocytes'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Why is a reflex faster than a decision? Partly because of fat. The axons that need to be fast are wrapped in insulation, and the spike stops sliding and starts leaping. The strange truth: to think faster, the brain doesn\'t change the signal — it changes the wire around it.',
      ),
      LessonSection.table(
        title: 'Bare vs Myelinated Axon',
        headers: ['Feature', 'Unmyelinated', 'Myelinated'],
        rows: [
          ['Conduction', 'Continuous, slow', 'Saltatory (jumps node to node)'],
          ['Speed', '~0.5–2 m/s', 'Up to ~120 m/s'],
          ['Energy per signal', 'Higher', 'Lower — fires only at nodes'],
          ['Gaps', 'None', 'Nodes of Ranvier'],
        ],
      ),
      LessonSection.fact(
        title: 'Top Speed',
        body:
            'Well-myelinated axons conduct at up to ~120 m/s — roughly 270 mph. The spike doesn\'t flow; it teleports from node to node.',
      ),
      LessonSection.thinkReveal(
        title: 'When the Insulation Fails',
        question:
            'In multiple sclerosis, the immune system strips myelin off axons. Predict what goes wrong — even though the neurons themselves are still alive.',
        answer:
            'Signals slow, scatter, and fail. Without insulation the spike leaks and can no longer leap cleanly, so messages arrive late, garbled, or not at all — causing weakness, numbness, and vision loss. The wire is intact; the insulation isn\'t. Speed was never free.',
      ),
    ],
  ),

  // 6 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_astrocytes',
    scale: BioScale.cell,
    position: 6,
    name: 'Astrocytes',
    title: 'The Star-Shaped Caretakers',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'Star-shaped glial cells that feed neurons, mop up stray ions and transmitter, and stand guard over the blood-brain barrier.',
    longDescription:
        'Astrocytes are star-shaped glial cells (astro = star) and the brain\'s tireless housekeepers. They wrap around synapses and blood vessels, ferrying nutrients from the bloodstream to hungry neurons and buffering the fluid around them — soaking up excess potassium after every burst of firing and clearing leftover glutamate before it becomes toxic.\n\n'
        'Their end-feet also clamp onto the brain\'s capillaries and help form the blood-brain barrier, the selective wall that keeps most bloodborne junk out of neural tissue. Far from passive glue, astrocytes actively shape which signals get through — they are part of the conversation, not just the room it happens in.',
    relatedIds: ['neuro_oligodendrocytes', 'neuro_microglia', 'neuro_synapse'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            '"Glia" comes from the Greek for glue — for a century we thought these cells just held neurons in place. They don\'t. Astrocytes feed neurons, clean up after every spike, and decide what your bloodstream is allowed to hand your brain. The scaffolding turned out to be running the building.',
      ),
      LessonSection.table(
        title: 'What Astrocytes Do',
        headers: ['Job', 'Why It Matters'],
        rows: [
          ['Ion buffering', 'Mop up K⁺ after firing so neurons can reset'],
          ['Glutamate clearance', 'Remove excess transmitter before it turns toxic'],
          ['Nutrient supply', 'Shuttle fuel from blood vessels to neurons'],
          ['Blood-brain barrier', 'End-feet help wall off the brain from the blood'],
          ['Synapse support', 'Help form, tune, and prune connections'],
        ],
      ),
      LessonSection.fact(
        title: 'Glia Everywhere',
        body:
            'Glial cells — astrocytes, oligodendrocytes, microglia, and more — roughly rival neurons in number, making up close to half the cells in the human brain.',
      ),
      LessonSection.thinkReveal(
        title: 'The Cleanup Crew',
        question:
            'Glutamate is the brain\'s main excitatory transmitter. What happens if astrocytes stop clearing it fast enough from the synapse?',
        answer:
            'It builds up and over-excites neurons — a condition called excitotoxicity that can literally kill them. This is part of the damage in stroke and injury. The "support" cell isn\'t optional: without astrocytes wiping the slate, the brain poisons itself with its own signal.',
      ),
    ],
  ),

  // 7 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_oligodendrocytes',
    scale: BioScale.cell,
    position: 7,
    name: 'Oligodendrocytes & Schwann Cells',
    title: 'The Myelin-Makers',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'The glial cells that actually build myelin — oligodendrocytes in the brain and spinal cord, Schwann cells everywhere else.',
    longDescription:
        'Myelin doesn\'t wrap itself. Two kinds of glial cell lay it down, and which one depends on where you are. In the central nervous system (CNS — brain and spinal cord), oligodendrocytes do the job, and a single oligodendrocyte can reach out and wrap segments of many different axons at once. In the peripheral nervous system (PNS — nerves out in the body), Schwann cells do it, and each Schwann cell wraps just one segment of one axon.\n\n'
        'The distinction matters clinically: PNS Schwann cells can help nerves regenerate after injury, while CNS oligodendrocytes largely cannot — one reason a cut finger nerve may recover but a spinal cord injury usually does not.',
    relatedIds: ['neuro_myelin', 'neuro_astrocytes', 'neuro_microglia'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Same job — insulate the wire — but two different workers, and the brain and the body chose differently. Why does a crushed nerve in your hand often heal, while the same damage in your spinal cord may be permanent? The answer is which cell shows up to rebuild the myelin.',
      ),
      LessonSection.table(
        title: 'CNS vs PNS Myelin-Makers',
        headers: ['Cell', 'Where', 'Wraps'],
        rows: [
          ['Oligodendrocyte', 'CNS (brain, spinal cord)', 'MANY axons at once'],
          ['Schwann cell', 'PNS (body nerves)', 'ONE axon segment each'],
        ],
      ),
      LessonSection.fact(
        title: 'The Rule to Memorize',
        body:
            'CNS myelin = OLIGODENDROCYTES. PNS myelin = SCHWANN CELLS. Both build the same fatty sheath; only the address differs.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Nerves Heal But the Cord Doesn\'t',
        question:
            'A severed peripheral nerve can slowly regrow; a severed spinal cord usually can\'t. Given who makes the myelin, why?',
        answer:
            'Schwann cells (PNS) actively clear debris and form guiding tracks that coax axons to regrow. Oligodendrocytes (CNS) don\'t — and the CNS environment actively inhibits regrowth. Same insulation, opposite repair behavior. Location isn\'t a detail; it\'s destiny.',
      ),
    ],
  ),

  // 8 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_microglia',
    scale: BioScale.cell,
    position: 8,
    name: 'Microglia',
    title: 'The Brain\'s Own Immune Force',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'The resident immune cells of the brain — restless sentries that patrol, eat debris and pathogens, and prune unused synapses.',
    longDescription:
        'The blood-brain barrier keeps ordinary immune cells out, so the brain grows its own defense force: microglia. Even when they look "resting," their fine branches are in constant motion, sweeping every corner of the tissue every few hours. When they detect damage, infection, or dead cells, they transform, swarm the site, and engulf the trouble by phagocytosis.\n\n'
        'But microglia aren\'t only cleanup. During development and learning they act as sculptors, pruning weak or unused synapses to sharpen circuits — an immune cell literally editing your wiring. Overactive microglia are now implicated in chronic pain and neurodegenerative disease, making them a hot target for research.',
    relatedIds: ['neuro_astrocytes', 'neuro_plasticity', 'neuro_synapse'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'The brain is walled off from your immune system — so it recruited its own. Microglia never sleep: even at rest they sweep the entire brain every few hours, and when something\'s wrong they swarm it. Stranger still, they don\'t just defend your circuits — they help build them by eating the connections you don\'t use.',
      ),
      LessonSection.table(
        title: 'The Many Jobs of Microglia',
        headers: ['Mode', 'Action'],
        rows: [
          ['Surveillance', 'Constantly sweep tissue for trouble'],
          ['Defense', 'Engulf pathogens and debris (phagocytosis)'],
          ['Pruning', 'Remove weak/unused synapses to refine circuits'],
          ['Signaling', 'Release molecules that call in a response'],
        ],
      ),
      LessonSection.fact(
        title: 'The Sentry',
        body:
            'Microglia are the CNS\'s resident immune cells — the ONLY defenders that live full-time behind the blood-brain barrier, roughly 10% of brain cells.',
      ),
      LessonSection.thinkReveal(
        title: 'A Double-Edged Sword',
        question:
            'Microglia prune synapses to sharpen a healthy brain. What might go wrong if they become over-active and prune too aggressively?',
        answer:
            'They can strip away healthy connections, and over-pruning is now linked to conditions from Alzheimer\'s to schizophrenia. The same cell that sculpts your circuits can, unchecked, tear them down. Defense and destruction are the same tool pointed different ways.',
      ),
    ],
  ),

  // 9 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'neuro_plasticity',
    scale: BioScale.cell,
    position: 9,
    name: 'Neuroplasticity & Learning',
    title: 'Wire Together, Fire Together',
    moduleId: 'cell_neurobiology',
    shortDescription:
        'Every skill and memory is a physical change: synapses that get used grow stronger, and neurons that fire together wire together.',
    longDescription:
        'Learning is not metaphorical — it is structural. When two neurons fire at nearly the same time, again and again, the synapse between them physically strengthens: more receptors, bigger connections, easier future firing. Neuroscientists summarize it as "neurons that fire together wire together" (Hebb\'s rule), and the best-studied form is long-term potentiation (LTP), a lasting boost in synaptic strength after repeated activation.\n\n'
        'The flip side, long-term depression, weakens synapses that go unused — use it or lose it. This ongoing rewiring is neuroplasticity, and it never fully stops. The brain you have tonight is not the brain you woke up with; reading this sentence has already nudged a synapse.',
    relatedIds: ['neuro_synapse', 'neuro_neurotransmitters', 'neuro_microglia'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'When you learn a phone number, something in your head physically changes shape. Memory isn\'t stored like a file — it\'s built like a muscle, one strengthened synapse at a time. The catch in "neurons that fire together wire together": do we really only keep what we practice? Mostly, yes.',
      ),
      LessonSection.table(
        title: 'Strengthen vs Weaken',
        headers: ['Process', 'What Happens', 'Result'],
        rows: [
          ['LTP (potentiation)', 'Repeated co-firing boosts the synapse', 'Learning, memory'],
          ['LTD (depression)', 'Unused synapse weakens', 'Forgetting, pruning'],
          ['Hebb\'s rule', 'Fire together → wire together', 'Circuits self-organize'],
        ],
      ),
      LessonSection.fact(
        title: 'The Principle',
        body:
            '"Neurons that fire together wire together." Long-term potentiation (LTP) is the lasting synaptic strengthening that lets a fleeting experience become a stored memory.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Practice Works',
        question:
            'Two people study a skill the same total time — one crams it in one night, the other spreads it over a week. Why does the spaced learner usually remember more?',
        answer:
            'LTP is built by repeated, separated activation, and each rest period lets the strengthened synapse consolidate before the next round. Spacing hits the same connection again and again over time, wiring it deeper. Cramming fires it hard once; practice wires it in. The saying is literal: repetition is rewiring.',
      ),
    ],
  ),
];
