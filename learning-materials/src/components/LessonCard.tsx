import { Link } from 'react-router-dom';
import type { LessonIndexEntry } from '../types/lesson';
import { useCompletedSteps } from '../hooks/useProgress';
import { ProgressBar } from './ProgressBar';

export function LessonCard({ entry }: { entry: LessonIndexEntry }) {
  const completed = useCompletedSteps(entry.id);
  const pct = entry.totalSteps ? Math.round((completed.length / entry.totalSteps) * 100) : 0;
  return (
    <Link to={`/lesson/${entry.id}`} className={`card size-${entry.size}`}>
      <span className="accent-bar" style={{ background: entry.accent }} />
      <span className="scale-tag">{entry.scale}</span>
      <h3>{entry.title}</h3>
      <p className="summary">{entry.summary}</p>
      {entry.careerCount > 0 && (
        <span className="careers-chip">💼 {entry.careerCount} career paths</span>
      )}
      <div className="progress">
        <ProgressBar percent={pct} label={pct > 0 ? `${pct}% complete` : 'Not started'} />
      </div>
    </Link>
  );
}
