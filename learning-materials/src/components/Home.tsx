import { lessonIndex } from '../lib/content';
import { LessonCard } from './LessonCard';

export function Home() {
  const lessons = lessonIndex.lessons;
  return (
    <div className="shell">
      <header className="topbar">
        <span className="brand">
          Explore The Cell<span className="dot">.</span> Lessons
        </span>
        <div className="spacer" />
        <span className="pill">{lessons.length} modules</span>
      </header>

      <main className="home">
        <section className="home-hero">
          <h1>
            The science <span className="grad">behind the games.</span>
          </h1>
          <p>
            Every Explore The Cell game has a lesson — scholarly, illustrated, and tied
            straight to what you play. Work through the steps, track your progress, and see
            the real careers each subject opens up.
          </p>
        </section>

        {lessons.length === 0 ? (
          <div className="empty">
            No lessons yet. Run the <code>sync-education</code> skill to generate them from the
            games' EDUCATION.md files.
          </div>
        ) : (
          <div className="bento">
            {lessons.map((entry) => (
              <LessonCard key={entry.id} entry={entry} />
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
