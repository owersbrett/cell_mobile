import type { Lesson, LessonIndex } from '../types/lesson';
import indexJson from '../content/lessons.index.json';

// The home grid reads the lightweight index (no full lesson bodies loaded).
export const lessonIndex = indexJson as LessonIndex;

// Full lessons are code-split: each JSON is fetched only when its module opens.
const modules = import.meta.glob<{ default: Lesson }>('../content/lessons/*.json');

export async function loadLesson(id: string): Promise<Lesson | null> {
  const path = `../content/lessons/${id}.json`;
  const loader = modules[path];
  if (!loader) return null;
  const mod = await loader();
  return (mod.default ?? (mod as unknown)) as Lesson;
}

/** Flatten every step id in a lesson, in document order. */
export function allStepIds(lesson: Lesson): string[] {
  return lesson.sections.flatMap((s) => s.steps.map((st) => st.id));
}
