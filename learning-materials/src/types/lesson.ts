// ─────────────────────────────────────────────────────────────────────────────
// THE LESSON CONTRACT
//
// This file is the keystone interface of the learning-materials app. It is the
// single agreement between:
//   • the PRODUCER — the `sync-education` skill, which reads each game's
//     EDUCATION.md (+ game_catalog metadata) and emits one Lesson JSON, and
//   • the CONSUMER — this web app, which renders that JSON into the two-panel
//     module view and the home bento.
//
// Source of truth flows ONE way: game → EDUCATION.md → (sync) → Lesson JSON → UI.
// The web app never authors lesson content; it only renders and tracks progress.
//
// Hierarchy: Lesson (the module / "the scale") ▸ Section ▸ Step ▸ ContentBlock[].
// Progress is measured at the STEP level and rolls up to section and module %.
// ─────────────────────────────────────────────────────────────────────────────

/** Home-page composition hint — how big this lesson's card renders in the bento. */
export type CardSize = 'large' | 'medium' | 'small';

/** A multimedia content block — the unit of "scholarly multimedia embedding". */
export type ContentBlock =
  | { type: 'markdown'; markdown: string }
  | { type: 'callout'; variant: 'note' | 'science' | 'potato' | 'warning'; markdown: string }
  | { type: 'quote'; markdown: string; cite?: string }
  | { type: 'equation'; tex: string; caption?: string }
  | { type: 'image'; src: string; alt: string; caption?: string }
  | {
      type: 'video';
      // `youtube` → src is a video id; `file` → src is a path under /media.
      provider: 'youtube' | 'file';
      src: string;
      caption?: string;
    }
  | { type: 'embed'; url: string; height?: number; caption?: string }
  | {
      // A direct, framed pointer back into the live game this lesson teaches.
      type: 'gameLink';
      label: string;
      // Deep-link/route understood by the host (explore-the-cell); free-form for now.
      target: string;
    };

/** A step — the smallest completable unit; drives the progress indicators. */
export interface LessonStep {
  id: string;
  title: string;
  /** Optional one-line objective shown in the left-panel tree. */
  objective?: string;
  body: ContentBlock[];
}

/** A section — a group of steps that contribute to its own and the module's progress. */
export interface LessonSection {
  id: string;
  title: string;
  /** Optional short framing shown above the section's steps on the right panel. */
  intro?: string;
  steps: LessonStep[];
}

/**
 * How accessible a career is — a gradient from "everyone's heard of it / low
 * barrier" to "esoteric, needs a deep field background". Ordered; the UI sorts
 * mainstream → frontier so a learner sees the on-ramp before the deep end.
 */
export type CareerTier =
  | 'mainstream'   // popular, widely known, low barrier to entry
  | 'professional' // an established career; typically needs a degree / credential
  | 'specialist'   // niche; needs strong domain background
  | 'frontier';    // esoteric; research-level / deep expertise helpful-to-necessary

export const CAREER_TIER_ORDER: Record<CareerTier, number> = {
  mainstream: 0,
  professional: 1,
  specialist: 2,
  frontier: 3,
};

/** A job/career the module's subject connects to — the "where this leads" layer. */
export interface CareerLink {
  /** e.g. "Astrophysicist", "Science communicator", "Gravitational-wave analyst". */
  title: string;
  tier: CareerTier;
  /** One line: what they do and how *this module's* topic shows up in the work. */
  blurb: string;
  /** What background helps or is required (e.g. "PhD in physics", "self-taught + portfolio"). */
  background: string;
}

/** A lesson — the module. The top scale of the hierarchy. */
export interface Lesson {
  /** Stable slug, also the JSON filename (e.g. "black-hole-heart"). */
  id: string;

  // ── Link back to the game (the reason this stays in sync) ──
  /** The game_catalog `id` this lesson teaches. The link sync follows. */
  gameId: string;
  /** Repo-relative path of the EDUCATION.md this lesson was derived from. */
  source: string;
  /** sha256 of the source EDUCATION.md at sync time — lets sync detect drift. */
  sourceHash: string;

  // ── Card / identity ──
  title: string;
  /** game_catalog scale key (e.g. "galactic", "organelle"). */
  scale: string;
  /** Hex accent inherited from the game's catalog accent. */
  accent: string;
  /** One-line hook for the home card. */
  summary: string;
  /** Bento sizing hint. */
  size: CardSize;
  /** Optional cover image (path under /media or remote). */
  cover?: string;

  // ── Body ──
  /** Module-level introduction ("the scale") — rendered at the top of the right panel. */
  intro: ContentBlock[];
  sections: LessonSection[];

  /**
   * Jobs/careers this whole module's subject connects to, mainstream → frontier.
   * The "where could this take you" payoff; also doubles as marketing surface.
   * May be empty for modules where it doesn't yet apply.
   */
  careers: CareerLink[];

  // ── Provenance ──
  /** ISO timestamp stamped by sync-education. */
  generatedAt: string;
  /** Contract version, so the app can refuse/upgrade stale shapes. */
  syncVersion: 1;
}

/** Lightweight record for the home grid (avoids loading every full lesson). */
export interface LessonIndexEntry {
  id: string;
  gameId: string;
  title: string;
  scale: string;
  accent: string;
  summary: string;
  size: CardSize;
  cover?: string;
  /** Total step count — used to compute % complete against stored progress. */
  totalSteps: number;
  /** How many careers this module surfaces — shown as a card affordance. */
  careerCount: number;
}

export interface LessonIndex {
  syncVersion: 1;
  generatedAt: string;
  lessons: LessonIndexEntry[];
}

export const CURRENT_SYNC_VERSION = 1 as const;
