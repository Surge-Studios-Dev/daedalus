# Corpus — the moat feature's quality gate

The differentiated feature (usually the AI pipeline) is the riskiest thing
in the app, so it gets proven FIRST, with numbers, before any UI consumes
it. This is the M0 gate: `npm run corpus` green on a 100+ item corpus is
the exit criterion for milestone 0, and the regression gate for every
quality-affecting pipeline change after (prompt edits, model swaps, parser
fixes — the same changes that bump `PIPELINE_VERSION`).

Ladle ran this shape at 110 items / 99-100% pass before a single screen
was built; every "quick prompt improvement" afterwards ran it again.

## Build the corpus

- Copy `corpus.example.json` to `corpus.json` and grow it to **100+ real
  items** covering every source type the pipeline claims to handle, in
  realistic proportions — plus deliberate junk (`"outcome": "fail"` items):
  a pipeline that never says "I can't" hallucinates instead.
- Wire `run_item.mjs` to the real pipeline (direct call, not the deployed
  callable — the corpus measures the pipeline, not the network).
- Set expectations per item: `equal` (exact fields), `min` (counts/lengths),
  `near` (numbers within a tolerance %). Expect only what a human would
  actually check.

## Run it

```
npm run corpus                    # full corpus + gate
npm run corpus -- --only=tiktok   # iterate on one source type (no gate)
npm run corpus -- --id=web-004    # one item (no gate)
```

Results land in `report.json`; failures are bucketed by reason so the next
fix is obvious.

## Rules that came from running Ladle's corpus

- **Never hammer rate-limited sources in loops.** List them in
  `serialTypes` — they run one-at-a-time with a gap. A parallel run
  against an oEmbed endpoint poisons the run AND the production cache
  with throttle failures.
- **Cache external fetches on disk** in `run_item.mjs` (keyed by URL hash)
  so re-runs are free, fast, and deterministic; add a `--no-cache` escape
  for when the source itself is the suspect.
- **The gate only binds on a full, unfiltered corpus** (`minItems`,
  default 100). A 10-item corpus at 100% says nothing; filtered runs are
  for iterating, not for shipping.
- **A/B model configs on the corpus, not on vibes.** Ladle's video
  pipeline kept API defaults because the hand-tuned "cheaper" config lost
  quantities — the corpus caught it.
