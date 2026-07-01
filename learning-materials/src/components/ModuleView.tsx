import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import type { Lesson } from '../types/lesson';
import { loadLesson } from '../lib/content';
import { setStepDone } from '../lib/progress';
import { useCompletedSteps } from '../hooks/useProgress';
import { Blocks } from './blocks/BlockRenderer';
import { Careers } from './Careers';
import { LeftPanel } from './LeftPanel';

export function ModuleView() {
  const { id = '' } = useParams();
  const [lesson, setLesson] = useState<Lesson | null>(null);
  const [state, setState] = useState<'loading' | 'ready' | 'notfound'>('loading');
  const [activeStepId, setActiveStepId] = useState<string | null>(null);

  const completedArr = useCompletedSteps(id);
  const completed = useMemo(() => new Set(completedArr), [completedArr]);
  const rightRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let alive = true;
    setState('loading');
    loadLesson(id).then((l) => {
      if (!alive) return;
      if (!l) return setState('notfound');
      setLesson(l);
      setState('ready');
    });
    return () => {
      alive = false;
    };
  }, [id]);

  // Scroll-spy: highlight the step currently in view in the left panel.
  useEffect(() => {
    if (!lesson) return;
    const nodes = Array.from(document.querySelectorAll<HTMLElement>('[data-step-id]'));
    if (nodes.length === 0) return;
    const obs = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible[0]) setActiveStepId(visible[0].target.getAttribute('data-step-id'));
      },
      { rootMargin: '-72px 0px -60% 0px', threshold: 0 },
    );
    nodes.forEach((n) => obs.observe(n));
    return () => obs.disconnect();
  }, [lesson]);

  const jump = (anchorId: string) => {
    const el = document.getElementById(`anchor-${anchorId}`);
    el?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  if (state === 'loading') return <div className="empty">Loading…</div>;
  if (state === 'notfound' || !lesson)
    return (
      <div className="empty">
        Lesson not found. <Link to="/">Back to all modules</Link>
      </div>
    );

  return (
    <div className="shell">
      <header className="topbar">
        <Link to="/" className="brand" style={{ textDecoration: 'none' }}>
          Explore The Cell<span className="dot">.</span>
        </Link>
        <span className="crumb">/ {lesson.scale} / {lesson.title}</span>
        <div className="spacer" />
        <span className="pill">{lesson.gameId}</span>
      </header>

      <div className="module">
        <LeftPanel
          lesson={lesson}
          completed={completed}
          activeStepId={activeStepId}
          onJump={jump}
        />

        <div className="right" ref={rightRef}>
          <article className="content">
            <h1 className="module-title">{lesson.title}</h1>
            <div className="intro">
              <Blocks blocks={lesson.intro} />
            </div>

            {lesson.sections.map((sec) => (
              <section className="section" id={`anchor-${sec.id}`} key={sec.id}>
                <h2>{sec.title}</h2>
                {sec.intro && <p className="sec-intro">{sec.intro}</p>}

                {sec.steps.map((st) => {
                  const done = completed.has(st.id);
                  return (
                    <div
                      className="step"
                      key={st.id}
                      id={`anchor-${st.id}`}
                      data-step-id={st.id}
                    >
                      <div className="step-head">
                        <h3>{st.title}</h3>
                      </div>
                      {st.objective && <p className="objective">{st.objective}</p>}
                      <Blocks blocks={st.body} />
                      <button
                        className={`step-complete-btn ${done ? 'done' : ''}`}
                        onClick={() => setStepDone(id, st.id, !done)}
                      >
                        {done ? '✓ Completed' : 'Mark complete'}
                      </button>
                    </div>
                  );
                })}
              </section>
            ))}

            <div id="anchor-careers">
              <Careers careers={lesson.careers} />
            </div>
          </article>
        </div>
      </div>
    </div>
  );
}
