# INTAKE.md · From idea to buildable app

The 1-week clock starts when the idea is fleshed out. This is the fleshing-out
ritual: answer six passes of questions, and the answers become a
`surge.manifest.yaml` (every question maps to a field) plus the inputs for the
spec. Run it as a conversation - with a person or with Claude - not as a form.

**The pipeline:**

```
idea -> INTAKE (this file) -> surge.manifest.yaml
     -> dart run tools/spec_gen  -> design/spec.md skeleton
     -> write Section 6 (screens) + Section 8 (edge cases)   <- the real work
     -> mason make daedalus      -> running app
     -> scripts/forge.sh         -> provisioned, launch checklist
```

An idea is *fleshed out* when: the manifest validates, spec Sections 1-5 and
10 are written, every P0 screen has a Section 6 block, and every feature tab
has 5+ edge cases in Section 8. Then - and only then - stamp.

---

## Defaults (propose, don't ask)

Known-good defaults, consolidated so the interview never spends a question
on them. Propose each one in passing; the human can veto. Any default taken
without an explicit yes - and any other guess made without asking - is
recorded as a `# ASSUME:` comment next to the manifest field, and migrates
to spec §12 Assumptions once the skeleton exists. Guessing is fine;
unlogged guessing is how specs and apps drift apart.

| Field | Default |
|---|---|
| Firebase project id | `<slug>-prod` (ids are global; fall back `<studio>-<slug>-prod`) |
| Support email | `support@<domain>` |
| Entitlement id | `pro` |
| Notifications | off in v1 (fast follow; needs server logic) |
| Remote Config | only if the trial is `app_gated` |
| Cross-promo slot | on |
| Tracking | off (ATT prompt + store-label consequences) |

If it touches product intent (pass 1), money, or legal: ask, don't default.

## Pass 1 · The idea (no manifest fields yet - this is the hard part)

1. **One-liner.** What is it, for whom, and what's the hook? If this takes
   more than one sentence, the idea isn't ready.
2. **The core loop.** What does the user do repeatedly? `A -> B -> C -> state
   compounds`. An app without a compounding loop is a utility - fine, but say
   so, because it changes monetization (one_time, not subscription).
3. **The quality bar.** Name the ONE behavior that must be flawless because
   incumbents fail it. (Ladle: the grocery list never drifts from the plan.)
   This is where the engineering time goes; everything else is standard.
4. **The positioning rule.** One sentence that settles disputed design calls
   in advance. What should this app *read as* at first glance, and what must
   never leak into that first impression?
5. **Why will this beat what exists?** If the honest answer is "it won't,
   but it's a niche the big ones ignore," that's a valid answer - write it
   down; it caps the marketing budget.

## Pass 2 · Shape → `navigation`, spec §3/§6

6. **Tabs.** 2-5, exactly one of which is the builtin profile/settings tab.
   For each: id (snake_case), label, lucide icon, `feature` or `builtin`.
   Fewer tabs is better; a tab must earn its slot by being a *place the user
   returns to*, not a feature that could live behind a button.
7. **Primary action.** Is there a center-button action reachable from every
   tab (Ladle's Add)? If yes: id, label, icon. If no, delete the field.
   The icon must be the app's own motif (Ember: flame), never a generic
   energy default - Ember shipped `zap` here and the user reported "a
   random lightning bolt on the toolbar." If the action is add, `plus` is
   the motif; otherwise reach for the identity icon already on a tab.
8. **Screens per tab.** Rough list per feature tab - just names, the spec
   skeleton assigns IDs. If a tab has >8 screens, it's probably two tabs or
   too big for v1.
9. **Phases.** Which screens are P0 (launch), P1 (fast follow), P2 (later)?
   Everything gets specced; only P0 gets built first.

## Pass 3 · Money → `monetization`, spec §4

10. **Model.** `subscription` (compounding loop, ongoing value),
    `one_time` (utility, pay once), or `hybrid`. Be honest per question 2.
11. **Free tier.** What does free include, as a list? Write this before
    picking gates - free is the product most users experience, and App Store
    review requires the app to be *usable* without paying.
12. **Gates.** Which features are paid? Each becomes a gate id (snake_case).
    Rule of thumb: gate depth (unlimited X, power features), never the core
    loop's first lap.
13. **Meter?** Is any gate a metered allowance (N per week) instead of a hard
    gate? Define: what counts, what doesn't, reset schedule, where the meter
    shows.
14. **Products + prices.** Reference prices for annual/monthly (subscription)
    or the one-time unlock. Entitlement id (default `pro`; Ladle used `plus`).
15. **Trial.** `store_intro_offer` (subscription; N days via the store),
    `app_gated` (one_time; N days enforced in-app), or `none`.

## Pass 4 · Data & risk → `legal.data_practices`, `integrations`, spec §8

16. **What user data exists?** Account email? User content (what kinds -
    this phrase goes verbatim into the privacy policy's content summary)?
    Photos? Location? Health data?
17. **Third parties.** Beyond the stock set (Firebase auth/analytics/
    Crashlytics, RevenueCat): AI providers? Other APIs? Each is an
    `extra_provider` in the legal manifest section.
18. **Tracking.** Cross-app tracking/ads? (Almost always `false` for Surge
    apps; `true` drags in ATT prompts and store-label consequences.)
19. **Domain disclaimers.** Health, food safety, financial, legal advice
    adjacency? One paragraph for the `domain_disclaimer` legal field.
20. **Age rating + category.** Store category and age rating.

## Pass 5 · Brand → `identity`, `brand`, spec §9

21. **Name + slug.** Working name is fine (Ladle shipped from a placeholder).
    slug is snake_case, permanent, and becomes the bundle id / deep-link
    scheme - choose like it's forever even if the name isn't.
22. **Tagline.** The one-liner from question 1, tightened to store-listing
    length.
23. **References first, then look.** Name 2-3 shipped apps whose look this
    app should sit beside (screenshots, not vibes). This question is not
    skippable: direction proposed without references drifted into the
    generic 2026 "AI app" look on Ladle (tomato/coral accents on warm
    paper) and had to be redone — that palette family is banned, and so is
    defaulting to whatever the template already looks like.
24. **Theme pack.** Pick the `brand.theme_pack` personality the references
    point at (`soft_depth` today; `canvas` is the unstyled blank canvas —
    never ship it as-is). No pack fits? That's a signal to design a new
    pack in surge_ui, not to bend the app onto a wrong one.
25. **Palette.** accent / accent_soft / panel hex values, tuned WITHIN the
    pack (the pack carries neutrals, shape, and motion). Dark-first or
    light-first?
26. **Fonts.** display + text. Start from the pack's recommended pairing
    (soft_depth: Manrope) and diverge only with a reason; fonts must be
    bundled assets.
27. **Logo mode.** `wordmark` or `monogram` (drives the site portfolio card).
28. **Banned vocabulary.** What words would betray the product's values?
    (Ladle banned diet-culture language app-wide.)

## Pass 6 · Ops → `integrations`, `studio`, `features`

29. **Firebase project id.** `<slug>-prod` unless there's a reason not to.
    Project ids are GLOBAL across all of Google Cloud - `ember-prod` was
    already taken by a stranger. Fall back to `<studio>-<slug>-prod` and
    update the manifest before provisioning.
30. **Support email.** `support@<domain>` - must exist before store
    submission.
31. **Notifications in v1?** If yes, spec §7 gets written (types, triggers,
    caps). Default no - it's a fast follow that needs server logic.
32. **Remote config in v1?** Needed for app_gated trials and kill switches.
33. **Cross-promo slot?** Show other Surge apps in settings (default yes).

---

## Output checklist

- [ ] `surge.manifest.yaml` written and `dart run bin/validate.dart` passes
      (from `tools/manifest_validator`)
- [ ] `design/spec.md` generated (`tools/spec_gen`), Sections 1-5 + 10 written
- [ ] Every P0 screen has a Section 6 block; every feature tab has 5+ edge
      cases in Section 8
- [ ] Prices sanity-checked against 2-3 comparable apps
- [ ] Name/slug checked: App Store search, domain, `slug://` collision
- [ ] Legal fields set (governing law, support email, content summary,
      disclaimers) - the generated policies are drafts for lawyer review

---

## Changelog

Meaning changes only, newest first, one line each.

- 2026-07-20 — "Defaults (propose, don't ask)" box consolidates the scattered defaults; unasked guesses logged as `# ASSUME:` comments that migrate to spec §12.

*Verified against code: 2026-07-20*
