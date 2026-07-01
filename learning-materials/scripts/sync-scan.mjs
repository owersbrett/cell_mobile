#!/usr/bin/env node
// sync-scan — the deterministic half of `sync-education`.
//
// Walks every EDUCATION.md under lib/games/**, hashes it, and compares against
// the lesson JSON the web app already has. Emits a manifest the authoring agent
// consumes so it only (re)writes lessons that are NEW or DRIFTED.
//
//   node learning-materials/scripts/sync-scan.mjs            # human-readable
//   node learning-materials/scripts/sync-scan.mjs --json     # machine manifest
//
// Source of truth: lib/games/**/EDUCATION.md  →  lesson JSON sourceHash.
// One-way flow. This script NEVER writes lessons; it only reports drift.

import { createHash } from 'node:crypto';
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const APP_ROOT = join(__dirname, '..');            // learning-materials/
const REPO_ROOT = join(APP_ROOT, '..');            // cell_mobile/
const GAMES_DIR = join(REPO_ROOT, 'lib', 'games');
const LESSONS_DIR = join(APP_ROOT, 'src', 'content', 'lessons');

const jsonMode = process.argv.includes('--json');

function walk(dir, hits = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    const st = statSync(p);
    if (st.isDirectory()) walk(p, hits);
    else if (name === 'EDUCATION.md') hits.push(p);
  }
  return hits;
}

function sha256(s) {
  return createHash('sha256').update(s).digest('hex');
}

// Index existing lessons by their `source` path.
const existingBySource = new Map();
if (existsSync(LESSONS_DIR)) {
  for (const f of readdirSync(LESSONS_DIR)) {
    if (!f.endsWith('.json')) continue;
    try {
      const l = JSON.parse(readFileSync(join(LESSONS_DIR, f), 'utf8'));
      if (l.source) existingBySource.set(l.source, { id: l.id, sourceHash: l.sourceHash });
    } catch {
      /* ignore malformed */
    }
  }
}

const manifest = [];
for (const eduPath of walk(GAMES_DIR)) {
  const rel = relative(REPO_ROOT, eduPath); // e.g. lib/games/galactic/black_hole/EDUCATION.md
  const content = readFileSync(eduPath, 'utf8');
  const hash = sha256(content);
  const existing = existingBySource.get(rel);
  let status;
  if (!existing) status = 'new';
  else if (existing.sourceHash !== hash) status = 'drifted';
  else status = 'current';
  manifest.push({
    source: rel,
    folder: relative(GAMES_DIR, dirname(eduPath)), // e.g. galactic/black_hole
    currentHash: hash,
    lessonId: existing?.id ?? null,
    storedHash: existing?.sourceHash ?? null,
    status,
  });
}

const summary = {
  total: manifest.length,
  new: manifest.filter((m) => m.status === 'new').length,
  drifted: manifest.filter((m) => m.status === 'drifted').length,
  current: manifest.filter((m) => m.status === 'current').length,
};

if (jsonMode) {
  process.stdout.write(JSON.stringify({ summary, items: manifest }, null, 2));
} else {
  console.log(`\nsync-scan — EDUCATION.md → lessons drift report`);
  console.log(`  total: ${summary.total}  new: ${summary.new}  drifted: ${summary.drifted}  current: ${summary.current}\n`);
  const todo = manifest.filter((m) => m.status !== 'current');
  if (todo.length === 0) {
    console.log('  ✓ all lessons in sync.\n');
  } else {
    for (const m of todo) console.log(`  [${m.status.toUpperCase()}] ${m.folder}  (${m.source})`);
    console.log('');
  }
}
