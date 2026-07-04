import 'dart:io';

import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 41 games built in the four-per-scale pass. The UX Refinement Pass
/// (docs/UX_REFINEMENT_PASS.md) gives each one a design teardown and a
/// UX-passed alternative. This test is the completion gate: it fails until
/// every game has both, so the goal loop runs until it's green, then deploys.
const List<String> kUxPassGames = [
  // organelle
  'organelle_match', 'membrane_gate', 'powerhouse',
  // cell
  'cell_type', 'osmosis', 'transcribe',
  // tissue
  'twitch', 'skin_layers', 'tissue_type',
  // organ (nephron judged → v2 promoted to canonical id)
  'heartbeat', 'body_map',
  // atoms
  'electron_shells', 'isotopes', 'half_life',
  // molecular
  'bond_lab', 'ph_balance', 'phase_change',
  // organSystem
  'digest', 'circulate', 'reflex',
  // organism (homeostasis + forage judged → v2 promoted to canonical id)
  'life_cycle',
  // ecosystem
  'food_web', 'predator_prey', 'nutrient_cycle',
  // nothings
  'tzimtzum', 'the_wait', 'quantum_foam',
  // somethings
  'pattern_lock',
  // particles (decay_chain: v2 judged winner → promoted to canonical id, no separate _v2)
  'standard_model', 'decay_chain',
  // infinities
  'converge', 'hilberts_hotel',
  // multiverseAll (superposition A/B resolved → v2 promoted to canonical)
  'branch', 'bubbles',
  // universeAll
  'powers_of_ten', 'cosmic_timeline', 'constants',
];

void main() {
  test('all 41 UX-pass games have a teardown (docs/ux_pass/teardowns/<id>.md)',
      () {
    final missing = [
      for (final id in kUxPassGames)
        if (!File('docs/ux_pass/teardowns/$id.md').existsSync()) '  $id',
    ];
    expect(
      missing,
      isEmpty,
      reason: 'Teardowns missing (${missing.length}/${kUxPassGames.length}):\n'
          '${missing.join('\n')}',
    );
  });

  // Games that no longer carry a separate <id>_v2 spec, so the alternative
  // requirement doesn't apply:
  //  • decay_chain    — v2 judged the winner, PROMOTED onto the canonical id.
  //  • standard_model — v2 judged the winner, PROMOTED onto the canonical id.
  //  • isotopes       — v2 retired; v1 stands on its own for now.
  const noSeparateV2 = {'decay_chain', 'standard_model', 'isotopes'};

  test('all 41 UX-pass games have an enabled <id>_v2 alternative wired', () {
    final enabledIds =
        MiniGameRegistry.enabledSpecs.map((s) => s.id).toSet();
    final missing = [
      for (final id in kUxPassGames)
        if (!noSeparateV2.contains(id) && !enabledIds.contains('${id}_v2'))
          '  ${id}_v2',
    ];
    expect(
      missing,
      isEmpty,
      reason: 'UX-passed alternatives missing '
          '(${missing.length}/${kUxPassGames.length}):\n${missing.join('\n')}',
    );
  });
}
