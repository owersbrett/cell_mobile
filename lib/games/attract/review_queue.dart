/// The **chat-configured review queue** — the games Brett and Claude are
/// actively reviewing/fixing right now.
///
/// This list is edited on request: when Brett says "queue X, Y, Z" (or "review
/// these"), Claude rewrites [kReviewQueue] to those games. It is played
/// hands-free from **ATTRACT → QUEUED GAMES**, so Brett can watch just the games
/// that matter cycle in autopilot and judge the fixes — no grading UI, no
/// hunting through the full ~130-game walk.
///
/// Entries are [MiniGameSpec] ids (see `mini_game_registry.dart`). Unknown ids
/// are skipped safely, so the queue never crashes if a game is renamed/removed.
/// Order here is the play order. Keep it short — this is a focus list, and it
/// changes often (some games earn their way off it once they're fun).
const List<String> kReviewQueue = <String>[
  // Game-triage Wave 2 (2026-07-08) — the "I don't understand how to score /
  // what's happening" cluster, each given a clarity/legibility pass (objective
  // line + live score feedback + fading how-to). Review these next.
  'orbital_insertion',
  'bottleneck',
  'stock_it',
  'reroute',
  'bonds',
  'spiral_arms',
  'galaxy_merger',
  'structure_formation',
  'stellar_evolution',
  'solar_storm',
  'portfolio',
  'digest',
];
