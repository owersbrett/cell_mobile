// Progress is tracked at the STEP level, persisted in localStorage, and exposed
// through a tiny pub/sub store so the home cards and the module view stay in sync.
// Section % and module % are derived from completed steps (see selectors below).

const KEY = 'etc-lessons:progress:v1';

type Store = Record<string, string[]>; // lessonId -> completed stepIds

const listeners = new Set<() => void>();

function read(): Store {
  try {
    return JSON.parse(localStorage.getItem(KEY) || '{}') as Store;
  } catch {
    return {};
  }
}

function write(store: Store): void {
  localStorage.setItem(KEY, JSON.stringify(store));
  listeners.forEach((l) => l());
}

export function subscribe(fn: () => void): () => void {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

/** Snapshot of completed step ids for a lesson (stable reference until it changes). */
const emptyArr: string[] = [];
const snapshotCache = new Map<string, string[]>();
export function getCompleted(lessonId: string): string[] {
  const next = read()[lessonId] ?? emptyArr;
  const prev = snapshotCache.get(lessonId);
  // Keep a stable reference when content is unchanged (useSyncExternalStore safety).
  if (prev && prev.length === next.length && prev.every((v, i) => v === next[i])) {
    return prev;
  }
  snapshotCache.set(lessonId, next);
  return next;
}

export function isStepDone(lessonId: string, stepId: string): boolean {
  return getCompleted(lessonId).includes(stepId);
}

export function setStepDone(lessonId: string, stepId: string, done: boolean): void {
  const store = read();
  const set = new Set(store[lessonId] ?? []);
  if (done) set.add(stepId);
  else set.delete(stepId);
  store[lessonId] = [...set];
  write(store);
}

export function toggleStep(lessonId: string, stepId: string): void {
  setStepDone(lessonId, stepId, !isStepDone(lessonId, stepId));
}

/** Fraction 0..1 of `stepIds` that are complete for the lesson. */
export function fractionDone(lessonId: string, stepIds: string[]): number {
  if (stepIds.length === 0) return 0;
  const done = new Set(getCompleted(lessonId));
  const n = stepIds.filter((id) => done.has(id)).length;
  return n / stepIds.length;
}

/** Percent (0..100, rounded) complete of a lesson given its total step count. */
export function modulePercent(lessonId: string, totalSteps: number): number {
  if (totalSteps === 0) return 0;
  return Math.round((getCompleted(lessonId).length / totalSteps) * 100);
}
