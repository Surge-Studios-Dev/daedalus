# MILESTONES.md · {{name}}

The build plan, in risk order: the most dangerous unknowns first, polish
last. Work ONE milestone (or one screen group inside M3) per session; read
`.daedalus/state.yaml` first and update it before ending. A milestone is
done when its exit criteria are checked, not when its code exists. The
merge bar (analyze clean + tests green + formatted) is enforced by the
committed `.claude` hook on every commit — it is not one of the criteria
because it is always true.

## M0 · Prove the moat

The differentiated feature is the riskiest thing in the app; prove it with
numbers before any UI consumes it (AI-RAIL.md).

- [ ] The moat feature's pipeline runs end to end (backend callable, real
      model client behind the seam in `backend/src/ai/extract.ts` if it is
      an AI surface)
- [ ] `backend/corpus/corpus.json` has 100+ real items including deliberate
      junk that must fail
- [ ] `npm run corpus` gates green (≥90% pass, p50 under the gate)
- [ ] No-AI apps: replace this milestone with the riskiest external
      dependency (device API, data source) proven the same way — a harness
      and a number, not a demo. Worked example: Ember's moat was widget
      freshness, proven as a pure policy engine behind a transport seam
      (`backend/src/freshness/engine.ts`) gated on a 115-scenario corpus
      (deterministic generator, hostile + invalid junk included) — the
      corpus items are simulated scenarios instead of URLs, and the first
      full run caught a real coalescer bug the unit tests missed

## M1 · Design direction locked

- [ ] Theme pack (`{{theme_pack}}`) reviewed against the INTAKE reference
      apps on the running app — not in theory
- [ ] Palette accent tuned in `surge.manifest.yaml`; fonts bundled
- [ ] `flutter test --update-goldens test/goldens` seeds the component
      goldens; suite green in both modes
- [ ] Screen board baseline captured
      (`flutter test --update-goldens test/goldens/screen_board.dart`) and
      the contact sheet eyeballed in light + dark

## M2 · Core logic (before any feature UI)

- [ ] Domain models in `lib/models/`, pure logic in `lib/core/` — no
      Flutter imports in core
- [ ] A unit test for every core function and every spec §8 edge case the
      logic owns; tests written against the spec text
- [ ] `.daedalus/state.yaml` gates.core_tests -> passed

## M3 · Features (parallelizable)

Reshape the generated pattern screens into the real spec §6 screens, one
screen group per session. After M2, feature tabs are independent — this is
the milestone to fan out across parallel agents (see Daedalus
`docs/parallel-build.md`).

- [ ] Every P0 screen from spec §6 built, carrying its spec ID doc comment
- [ ] Each screen's §8 edge cases are tests before it is called done
- [ ] Screen board re-captured after each screen group; compared against
      the reference direction in both modes
- [ ] Gated features show the Plus chip and route through
      `ref.gate(...)` — visible, never hidden

## M4 · Monetization proven

- [ ] Paywall shows the real products from the manifest; purchase +
      restore complete against the mock (StoreKit config / sandbox when
      provisioned)
- [ ] Metered free tier (if any) charges on success, never on save, and
      the at-limit gate routes to the paywall
- [ ] Telemetry: the standard funnel events fire (paywall_view,
      trial_start, purchase, restore, gate_blocked)

## M5 · Growth rail

- [ ] Referral loop verified end to end on the mock backend (invite ->
      redeem -> credit)
- [ ] Content sharing wired for the manifest's `sharing.content` types (if
      declared)

## M6 · Hardening

- [ ] Full spec §8 sweep: every edge case is a named test or has a written
      reason it is not
- [ ] A11y pass: labels on interactive elements, contrast spot-check on
      real screens, text scale 1.3 doesn't break layouts
- [ ] Bug sweep with fresh eyes (or a review agent); findings triaged and
      the P0/P1s fixed

## M7 · Ship

- [ ] `scripts/forge.sh` run; every LAUNCH-TODO retired or accepted
- [ ] `tools/ship_check` green
- [ ] Store screenshots generated from the screen board; metadata reviewed
- [ ] Provisioning done (Firebase live seams flipped, RevenueCat products,
      store records) and one sandbox purchase verified
- [ ] Submitted. `.daedalus/state.yaml` stage -> shipped
