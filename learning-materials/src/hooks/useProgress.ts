import { useSyncExternalStore } from 'react';
import { getCompleted, subscribe } from '../lib/progress';

/** Reactive list of completed step ids for a lesson. */
export function useCompletedSteps(lessonId: string): string[] {
  return useSyncExternalStore(
    subscribe,
    () => getCompleted(lessonId),
    () => getCompleted(lessonId),
  );
}
