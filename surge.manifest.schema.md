# surge.manifest.schema.md · `surge.manifest.yaml`

The single source of truth for one Surge app. It lives at the app repo root and is read by four consumers:

1. **The Flutter app** (build flavor, theme tokens, nav, auth, monetization, feature toggles).
2. **The Next.js site** (the app's portfolio entry and marketing page). This generalizes the typed shape you already use in `src/content/portfolio.ts`.
3. **Store metadata** generation (listing copy, category, keywords, age rating).
4. **`scripts/forge.sh`** (Firebase, bundle ids, RevenueCat, icon/splash, legal drafts).

Rule: if a value can live in the manifest, it never gets hardcoded anywhere else.

---

## Full example (subscription model)

```yaml
# surge.manifest.yaml
schema: 1

identity:
  slug: ladle                       # lowercase, unique across the portfolio
  name: Ladle
  tagline: Any recipe, one plan.
  bundle_id_ios: com.surgestudios.ladle
  package_android: com.surgestudios.ladle

studio:
  name: Surge Studios
  support_email: support@surgestudios.dev
  marketing_site: https://surgestudios.dev

brand:
  theme_pack: soft_depth            # design personality: canvas | soft_depth
  palette:                          # tunes the accent within the pack
    accent: "#75D8FF"
    accent_soft: "#2B89D8"
    panel: "#0E1B27"
  logo_mode: wordmark               # wordmark | monogram
  fonts:
    display: Fraunces
    text: Inter

navigation:
  tabs:                             # order = bar order; 2 to 5 tabs
    - id: library
      label: Library
      icon: book-open
      type: feature                 # feature (stub to fill) | builtin
    - id: plan
      label: Plan
      icon: calendar
      type: feature
    - id: you
      label: You
      icon: user
      type: builtin                 # rendered by modules/settings
  primary_action:                   # optional center action; omit for none
    id: add
    label: Add
    icon: plus

auth:
  providers: [email, apple, google] # apple is force-added if any social is present
  guest_mode: true                  # try-before-signup

monetization:
  entitlement: pro                  # single RevenueCat entitlement unlocking paid value
  model: subscription               # subscription | one_time | hybrid
  trial:
    type: store_intro_offer         # store_intro_offer | app_gated | none
    duration_days: 7
  products:
    - id: pro_annual
      type: auto_renew_subscription
      period: P1Y                   # ISO 8601 duration
      reference_price: 39.99        # marketing/docs only; real price set in store
      default: true
    - id: pro_monthly
      type: auto_renew_subscription
      period: P1M
      reference_price: 5.99
  gates: [import, export, collections]   # feature ids hidden behind `pro`

features:
  remote_config: true
  notifications: false
  cross_promo: true

sharing:                            # the growth rail (SHARING.md); omit = referrals on with defaults
  referrals: true                   # invite loop; default true, false opts out
  reward:
    type: entitlement_days          # the only reward type today
    per_referral: 7                 # days granted per successful referral
    cap: 90                         # lifetime cap per account
  link_domain: go.ladle.kitchen     # optional custom domain (no scheme); *.web.app fallback always works
  content: [recipe, collection]     # shareable type ids; omit for referral-only

legal:
  privacy_url: https://surgestudios.dev/ladle/privacy
  terms_url: https://surgestudios.dev/ladle/terms
  governing_law: the State of Alabama      # optional; ToS governing-law clause
  content_summary: recipes and meal plans  # optional; the app's user content, mid-sentence
  domain_disclaimer: >-                     # optional; extra ToS disclaimer (e.g. health, finance)
    Ladle provides general information, not professional or medical advice.
  extra_providers:                          # optional; extra data processors, "Name (purpose)"
    - Google Gemini (recipe import)
  data_practices:                   # drives the privacy policy + store data labels
    collects_email: true
    analytics: true
    crash_reporting: true
    tracking: false                 # true => template shows the ATT prompt

store:
  category: Food & Drink
  age_rating: "4+"
  keywords: [recipes, meal plan, grocery list]
  short_description: Any recipe, one plan.
  full_description: |
    Save recipes from anywhere and turn them into a weekly plan,
    with a grocery list that stays in sync.

integrations:
  firebase_project: ladle-prod      # flutterfire configure targets this
  revenuecat_api_key: ${REVENUECAT_KEY}   # a secret reference, never the value
```

---

## One-time purchase variant

Only the `monetization` block changes. Everything else is identical.

```yaml
monetization:
  entitlement: pro
  model: one_time
  trial:
    type: app_gated                 # no store trial; the app enforces the window
    duration_days: 14               # from first launch; tunable via Remote Config
  products:
    - id: pro_lifetime
      type: non_consumable
      reference_price: 14.99
      default: true
  gates: [all]                      # everything behind a single unlock
```

The `gate()` helper and entitlement check are the same in both cases. Only the trial mechanism and product types differ, and the template selects them off `model` and `trial.type`.

---

## Field reference

**identity** - `slug` is the portfolio-unique key used for repo naming, the site route, and cross-promo targeting. `bundle_id_ios` / `package_android` feed the build flavor and the init script.

**studio** - shared across the portfolio; the init script can default these from a studio-level config so you only set them once.

**brand** - `theme_pack` selects the design personality from surge_ui's `SurgeThemePacks` (default `canvas`, the neutral blank canvas; `soft_depth` is the first shipped personality). The pack carries the whole look — neutrals, shape, elevation, motion; `palette` then tunes the accent within it (any token you omit inherits the pack). INTAKE pass 5 requires 2-3 reference apps before this gets set; never default a shipping app to `canvas`. `fonts` must be bundled assets; packs recommend a pairing (soft_depth: Manrope) and forge notes a mismatch. The site reads this block to theme the marketing page so app and page match.

**navigation** - `tabs` builds the go_router shell. `type: builtin` is reserved for the settings/"You" tab rendered by `modules/settings`; `type: feature` generates a wired stub under `features/<id>`. `icon` values are `lucide_icons` names. `primary_action` is optional.

**auth** - `providers` from `email | apple | google`. Apple is force-included whenever a social provider is present, to satisfy Guideline 4.8. `guest_mode` toggles the try-before-signup path.

**monetization** - one entitlement per app. `model` picks subscription, one_time, or hybrid. `trial.type` must be consistent with `model` (`store_intro_offer` for subscriptions, `app_gated` for one_time, `none` to disable). `products[].type` is `auto_renew_subscription` or `non_consumable`. `reference_price` is never the source of truth for billing; the stores are. `gates` lists the feature ids `gate()` protects; `all` gates the entire app behind the unlock.

**features** - module toggles. `remote_config` enables the per-app kill-switch and the tunable trial window. `cross_promo` enables the house-ads slot.

**sharing** - the growth rail (see `SHARING.md`). `referrals` defaults to **true** — every app ships the invite loop unless explicitly opted out. `reward` is optional (absent = studio defaults: 7 days per referral, cap 90) but must be coherent when present: `type: entitlement_days` with `per_referral > 0` and `cap >= per_referral`, and it cannot be combined with `referrals: false`. `link_domain` is a bare domain (no scheme); the `*.web.app` default host always stays registered so old links never die. `content` lists the app's shareable type ids (snake_case); omit it for referral-only sharing.

**legal** - URLs back the in-app Privacy/Terms screens and the store listing. `data_practices` drives the generated Privacy Policy, Terms of Service, Apple privacy manifest, and the store data-disclosure labels (via `tools/legal_gen`); setting `tracking: true` wires the ATT prompt. The optional `governing_law`, `content_summary`, `domain_disclaimer`, and `extra_providers` tailor the generated copy to the app; omit them for correct-but-generic text. Generated per-app policies are hosted on the marketing site at `/<slug>/privacy` and `/<slug>/terms`, which is what `privacy_url` / `terms_url` should point to.

**store** - listing metadata consumed by the store-metadata generator. `full_description` supports multi-line block scalars.

**integrations** - `firebase_project` is the target for `flutterfire configure`. Any key ending in a `${VAR}` reference is resolved from CI/env at build time and must never hold a literal secret.

---

## Secrets policy

The manifest is committed to the repo, so it holds **references, not values**. Anything sensitive (RevenueCat keys, signing material, service-account JSON) is a `${VAR}` reference resolved from CI or a local `.env` that is gitignored. `forge.sh` validates that every `${VAR}` resolves before a build, and fails loudly if one is missing rather than shipping a broken paywall.
