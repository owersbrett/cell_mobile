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

// --- Stage 1: the ribbon — one smooth road through the walk order --------

/// Dark groove width (× node radius) — the road bed under the glow.
const double kRibbonGrooveWidthFactor = 0.85;

/// Soft colored glow stroke width (× node radius) and its alpha.
const double kRibbonGlowWidthFactor = 0.50;
const double kRibbonGlowAlpha = 0.30;

/// Crisp core line width (× node radius) and alpha, on top of the glow.
const double kRibbonCoreWidthFactor = 0.14;
const double kRibbonCoreAlpha = 0.75;

/// The traveling pulse: seconds for one full run START → DESTINATION
/// (direction of play — INWARD on Down the Hole), window length as a
/// fraction of the whole path, stroke width (× node radius), peak alpha,
/// and how many comets ride the road at once (evenly phase-spread so one is
/// usually on screen — checkpoint: a single comet was never seen).
const double kRibbonPulsePeriodSec = 12.0;
const double kRibbonPulseWindowFrac = 0.05;
const double kRibbonPulseWidthFactor = 0.36;
const double kRibbonPulseAlpha = 0.85;
const int kRibbonPulseCount = 2;

// --- Stage 1: breathing variants ------------------------------------------

/// Power-up (⚡) tiles breathe faster and brighter than ordinary tiles.
const double kPowerPulsePeriodSec = 2.1;
const double kPowerPulseAlphaBoost = 1.35;

/// The anchor's heartbeat: slow, deep, gold — the gravitational landmark.
/// A glow thump plus an expanding ring per beat (checkpoint: glow alone was
/// imperceptible under the anchor node's own shadow).
const double kAnchorHeartbeatPeriodSec = 2.9;
const double kAnchorGlowAlphaMax = 0.85;
const double kAnchorGlowRadiusFactor = 1.7; // extra radius on top of 2.1×
const double kAnchorRingAlpha = 0.6;
const double kAnchorRingSpread = 2.2; // ring travels to this × anchor radius

// --- Stage 1: gem glints ---------------------------------------------------

/// A diamond glints once per period (phase-offset per gem); the glint lasts
/// this fraction of the period.
const double kGemGlintPeriodSec = 6.5;
const double kGemGlintWidthFrac = 0.06;

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

/// A fork-arm step or a ladder/snake/slide covers MANY node-gaps in one
/// move — it glides over this longer duration (token AND camera) instead of
/// the normal hop so the traversal stays readable.
const int kJumpSlideMs = 700;

/// Hard zoom-out limit — low enough that a pinch-out (or -- button) fits the
/// ENTIRE square board in the viewport at once.
const double kZoomOutMin = 0.05;

/// Below this zoom the furniture stops counter-scaling (node/stroke sizes
/// freeze in world units), so zooming further out shrinks the board into a
/// readable minimap of dots instead of 88 overlapping constant-size circles.
const double kCounterScaleFloor = 0.4;
