import { Link } from 'react-router-dom';
import type { Lesson } from '../types/lesson';
import { ProgressBar } from './ProgressBar';

export function LeftPanel({
  lesson,
  completed,
  activeStepId,
  onJump,
}: {
  lesson: Lesson;
  completed: Set<string>;
  activeStepId: string | null;
  onJump: (id: string) => void;
}) {
  const totalSteps = lesson.sections.reduce((n, s) => n + s.steps.length, 0);
  const doneCount = lesson.sections.reduce(
    (n, s) => n + s.steps.filter((st) => completed.has(st.id)).length,
    0,
  );
  const modulePct = totalSteps ? Math.round((doneCount / totalSteps) * 100) : 0;

  return (
    <aside className="left">
      <Link to="/" className="back">
        ← All modules
      </Link>
      <div className="scale-line" style={{ color: lesson.accent }}>
        {lesson.scale}
      </div>
      <h2>{lesson.title}</h2>

      <div className="module-progress">
        <ProgressBar percent={modulePct} label={`${modulePct}% of module complete`} />
      </div>

      <ul className="toc">
        {lesson.sections.map((sec) => {
          const total = sec.steps.length;
          const done = sec.steps.filter((st) => completed.has(st.id)).length;
          const pct = total ? Math.round((done / total) * 100) : 0;
          return (
            <li className="sec" key={sec.id}>
              <button className="sec-title step" onClick={() => onJump(sec.id)}>
                {sec.title}
                <span className="sec-pct">{pct}%</span>
              </button>
              <ul className="steps">
                {sec.steps.map((st) => {
                  const isDone = completed.has(st.id);
                  return (
                    <li key={st.id}>
                      <button
                        className={`step ${activeStepId === st.id ? 'active' : ''}`}
                        onClick={() => onJump(st.id)}
                      >
                        <span className={`check ${isDone ? 'done' : ''}`}>{isDone ? '✓' : ''}</span>
                        {st.title}
                      </button>
                    </li>
                  );
                })}
              </ul>
            </li>
          );
        })}
        {lesson.careers.length > 0 && (
          <li className="sec">
            <button className="sec-title step" onClick={() => onJump('careers')}>
              Where this leads
              <span className="sec-pct">💼 {lesson.careers.length}</span>
            </button>
          </li>
        )}
      </ul>
    </aside>
  );
}
