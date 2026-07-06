#!/usr/bin/env node
// Corpus harness - the numeric quality gate for the app's moat feature
// (AI-RAIL.md). Runs every corpus item through run_item.mjs, scores the
// output against each item's expectations, and gates on pass rate +
// median latency. `npm run corpus` must pass before any UI consumes the
// pipeline (the M0 gate), and again before quality-affecting changes ship.
//
// Usage:
//   npm run corpus                    # full corpus
//   npm run corpus -- --only=tiktok   # one item type
//   npm run corpus -- --id=tt-001     # one item
//   npm run corpus -- --limit=10      # first N items
import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { runItem } from "./run_item.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v ?? true];
  }),
);

async function loadCorpus() {
  try {
    return JSON.parse(await readFile(path.join(here, "corpus.json"), "utf8"));
  } catch {
    console.error(
      "corpus/corpus.json not found. Copy corpus.example.json and grow it " +
        "to 100+ real items before trusting the gate (see corpus/README.md).",
    );
    process.exit(1);
  }
}

/** Score one item's output against its `expect` block. Returns reasons. */
function score(item, out) {
  const reasons = [];
  const expect = item.expect ?? {};
  const wantOk = (expect.outcome ?? "ok") === "ok";
  if (Boolean(out?.ok) !== wantOk) {
    reasons.push(wantOk ? `expected ok, got ${out?.error ?? "not ok"}` : "expected failure, got ok");
    return reasons; // outcome mismatch makes field checks noise
  }
  if (!wantOk) return reasons;
  for (const [field, want] of Object.entries(expect.equal ?? {})) {
    if (out[field] !== want) reasons.push(`${field}: expected ${JSON.stringify(want)}, got ${JSON.stringify(out[field])}`);
  }
  for (const [field, min] of Object.entries(expect.min ?? {})) {
    const got = Array.isArray(out[field]) ? out[field].length : out[field];
    if (!(typeof got === "number" && got >= min)) reasons.push(`${field}: expected >= ${min}, got ${got}`);
  }
  for (const [field, near] of Object.entries(expect.near ?? {})) {
    const got = out[field];
    const pct = near.pct ?? 10;
    if (typeof got !== "number" || Math.abs(got - near.value) > (near.value * pct) / 100) {
      reasons.push(`${field}: expected ${near.value} ±${pct}%, got ${got}`);
    }
  }
  return reasons;
}

function percentile(sorted, p) {
  if (sorted.length === 0) return 0;
  return sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * p))];
}

const corpus = await loadCorpus();
let items = corpus.items ?? [];
if (args.only) items = items.filter((i) => i.type === args.only);
if (args.id) items = items.filter((i) => i.id === args.id);
if (args.limit) items = items.slice(0, Number(args.limit));
if (items.length === 0) {
  console.error("no corpus items match the filters");
  process.exit(1);
}

// serialTypes run one-at-a-time with a gap: rate-limited sources (oEmbed
// endpoints) ban hammering - a parallel corpus run against them poisons
// both the run AND the cache with throttle failures.
const serialTypes = new Set(corpus.serialTypes ?? []);
const concurrency = corpus.concurrency ?? 3;
const serialGapMs = corpus.serialGapMs ?? 1000;

const results = [];
const serialQueue = items.filter((i) => serialTypes.has(i.type));
const parallelQueue = items.filter((i) => !serialTypes.has(i.type));

async function runOne(item) {
  const startedAt = Date.now();
  let out;
  try {
    out = await runItem(item);
  } catch (err) {
    out = { ok: false, error: err.message };
  }
  const latencyMs = Date.now() - startedAt;
  const reasons = score(item, out);
  const pass = reasons.length === 0;
  console.log(`${pass ? "PASS" : "FAIL"}  ${item.id}  ${(latencyMs / 1000).toFixed(1)}s${pass ? "" : `  ${reasons.join("; ")}`}`);
  results.push({ id: item.id, type: item.type, pass, reasons, latencyMs });
}

const serialRun = (async () => {
  for (const item of serialQueue) {
    await runOne(item);
    await new Promise((r) => setTimeout(r, serialGapMs));
  }
})();
let cursor = 0;
const workers = Array.from({ length: concurrency }, async () => {
  while (cursor < parallelQueue.length) {
    const item = parallelQueue[cursor++];
    await runOne(item);
  }
});
await Promise.all([serialRun, ...workers]);

const passed = results.filter((r) => r.pass).length;
const passPct = (passed / results.length) * 100;
const latencies = results.map((r) => r.latencyMs).sort((a, b) => a - b);
const p50 = percentile(latencies, 0.5);
const p95 = percentile(latencies, 0.95);

const failsByReason = {};
for (const r of results.filter((x) => !x.pass)) {
  for (const reason of r.reasons) {
    const bucket = reason.split(":")[0];
    failsByReason[bucket] = (failsByReason[bucket] ?? 0) + 1;
  }
}

console.log(`\n${passed}/${results.length} passed (${passPct.toFixed(1)}%)  p50 ${(p50 / 1000).toFixed(1)}s  p95 ${(p95 / 1000).toFixed(1)}s`);
if (Object.keys(failsByReason).length) {
  console.log("failures by reason:", failsByReason);
}

const gate = { passPct: 90, p50Ms: 20_000, minItems: 100, ...(corpus.gate ?? {}) };
const report = { ranAt: new Date().toISOString(), gate, passPct, p50, p95, results };
await writeFile(path.join(here, "report.json"), JSON.stringify(report, null, 2));

// An incomplete corpus can't gate honestly: a 10-item corpus at 100% says
// nothing. Report, but only enforce once the corpus is real. Filters
// (--only/--id/--limit) never gate - they're for iterating on failures.
const filtered = args.only || args.id || args.limit;
if (filtered || items.length < gate.minItems) {
  console.log(`gate SKIPPED (${filtered ? "filtered run" : `corpus < ${gate.minItems} items`}) - grow the corpus; the gate is the point.`);
  process.exit(0);
}
const pass = passPct >= gate.passPct && p50 <= gate.p50Ms;
console.log(`gate ${pass ? "PASSED" : "FAILED"} (need >= ${gate.passPct}% pass, p50 <= ${gate.p50Ms / 1000}s)`);
process.exit(pass ? 0 : 1);
