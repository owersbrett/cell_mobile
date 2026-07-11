/// Board-life tuning — every ambient/FX parameter for the board overhaul
/// (docs/board-render-recon.md → Phase 1) lives HERE, so checkpoint feedback
/// ("pulse slower", "glow quieter") is a 30-second constant edit, not a code
/// hunt.
///
/// View-layer only: nothing in this file may be read by PartyController or
/// otherwise influence game state (lockstep purity). All sizes are WORLD
/// units relative to the already-counter-scaled node radius, so they inherit
/// the constant-on-screen-size behavior automatically.
library;

/// Which GameMaps run the ambient life layer. Styling is per-board; the
/// legacy 52-space ring (gameMap == null) and unlisted maps render exactly
/// as before.
const Set<String> kBoardLifeMaps = {'down_the_hole'};

/// Golden-angle phase step (radians): per-element phase = index * this, so
/// neighbors never pulse in unison and no per-frame state is stored.
const double kGoldenPhase = 2.3999632297286533;

/// Viewport culling pad, in node radii — elements this far outside the
/// visible world rect still draw so nothing pops at the screen edge.
const double kAmbientCullPadNodeRadii = 4.0;

// --- Stage 0 placeholder: tile under-glow breathing (refined in Stage 1) ---
// Checkpoint 2026-07-10: first values (alpha peak 0.15, blur 0.55) were below
// the perceptual floor on the dark board — invisible. Boosted to clearly
// readable; Stage 1 retunes against the real ribbon/strata content.

/// One full breath, seconds.
const double kTilePulsePeriodSec = 3.6;

/// Under-glow disc radius as a multiple of the tile's own radius.
const double kTilePulseGlowFactor = 2.1;

/// Breathing amplitude: glow scales 1.0 → 1.0 + this across a breath.
const double kTilePulseScaleAmp = 0.16;

/// Glow opacity floor and swing (alpha = min + amp * breath).
const double kTilePulseAlphaMin = 0.10;
const double kTilePulseAlphaAmp = 0.30;

/// Softness of the glow edge: blur sigma as a fraction of node radius.
const double kTilePulseBlurFactor = 0.35;

// --- Walk feel: the board-game hop (checkpoint 2026-07-10, PARTY UX LAW) ---
// The token HOPS node-to-node and visibly SETTLES on each node before the
// next hop; the camera glides in lockstep with every hop and rests with the
// character. One step = hop (kWalkHopMs) + settle (the remainder of
// kWalkStepPeriodMs).

/// Duration of one node-to-node hop — the token slide AND the camera glide,
/// started the same tick so they arrive together.
const int kWalkHopMs = 240;

/// Full step cadence (hop + settle). Must exceed [kWalkHopMs]; the difference
/// is the visible rest on each node that makes movement read as board-game
/// steps instead of continuous sliding.
const int kWalkStepPeriodMs = 520;

/// Camera zoom while the character is WALKING — wider than the resting frame
/// zoom (1.45) so the player sees several spaces ahead during a move
/// (checkpoint 2026-07-10). The camera glides out to this as the walk begins
/// and back in on the next re-frame.
const double kWalkCameraZoom = 0.3;
