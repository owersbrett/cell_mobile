import { CAREER_TIER_ORDER, type CareerLink, type CareerTier } from '../types/lesson';

const TIER_LABEL: Record<CareerTier, string> = {
  mainstream: 'Mainstream',
  professional: 'Professional',
  specialist: 'Specialist',
  frontier: 'Frontier',
};

const TIER_HINT: Record<CareerTier, string> = {
  mainstream: 'widely known · low barrier',
  professional: 'established · degree-track',
  specialist: 'niche · strong background',
  frontier: 'esoteric · deep expertise',
};

/**
 * Where this module can take you. Careers are sorted mainstream → frontier so a
 * learner sees the on-ramp before the deep end. Each row names the background
 * that helps or is required.
 */
export function Careers({ careers }: { careers: CareerLink[] }) {
  if (!careers || careers.length === 0) return null;
  const sorted = [...careers].sort(
    (a, b) => CAREER_TIER_ORDER[a.tier] - CAREER_TIER_ORDER[b.tier],
  );
  return (
    <section className="section" id="careers" style={{ scrollMarginTop: 72 }}>
      <h2>Where this leads</h2>
      <p className="sec-intro">
        Jobs this subject opens up — from the widely known to the deep specialist roles
        where a strong field background is helpful or necessary.
      </p>
      <div className="careers">
        {sorted.map((c, i) => (
          <div className={`career tier-${c.tier}`} key={i}>
            <div className="career-head">
              <span className="career-title">{c.title}</span>
              <span className={`career-tier t-${c.tier}`} title={TIER_HINT[c.tier]}>
                {TIER_LABEL[c.tier]}
              </span>
            </div>
            <p className="career-blurb">{c.blurb}</p>
            <p className="career-bg">
              <strong>Background:</strong> {c.background}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
