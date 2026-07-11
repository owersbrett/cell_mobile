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

/// One full breath, seconds.
const double kTilePulsePeriodSec = 4.6;

/// Under-glow disc radius as a multiple of the tile's own radius.
const double kTilePulseGlowFactor = 1.55;

/// Breathing amplitude: glow scales 1.0 → 1.0 + this across a breath.
const double kTilePulseScaleAmp = 0.08;

/// Glow opacity floor and swing (alpha = min + amp * breath).
const double kTilePulseAlphaMin = 0.05;
const double kTilePulseAlphaAmp = 0.10;

/// Softness of the glow edge: blur sigma as a fraction of node radius.
const double kTilePulseBlurFactor = 0.55;
