# The manifest: single source of truth

*Part of the [Daedalus wiki](README.md) · related: [Pipeline](pipeline.md),
[Brick](brick.md), [Compliance & Web](compliance-and-web.md) · schema:
[surge.manifest.schema.md](../surge.manifest.schema.md)*

`surge.manifest.yaml` is the one file a human edits to configure an app.
Everything else is **derived** — and rederivable when the manifest changes.
The worked example is [`surge.manifest.example.yaml`](../surge.manifest.example.yaml)
("Tally", a *fictional* demo app); the real shipping example is
[`examples/ladle.manifest.yaml`](../examples/ladle.manifest.yaml).

## Everything the manifest drives

```mermaid
flowchart TB
    M[("surge.manifest.yaml")]

    M -->|"bricks/daedalus<br/>(pre_gen → mustache → post_gen)"| A["📱 App<br/>palette · fonts · tabs · nav ·<br/>auth providers · entitlement ·<br/>trial CTA · .firebaserc"]
    M -->|tools/spec_gen| S["📋 design/spec.md<br/>screen inventory + IDs ·<br/>gating table · deep links"]
    M -->|tools/legal_gen| L["⚖️ legal/<br/>privacy.md · terms.md · legal.json ·<br/>PrivacyInfo.xcprivacy · store labels"]
    M -->|tools/store_gen| ST["🏪 fastlane/metadata<br/>deliver (iOS) + supply (Play)<br/>with char-limit checks"]
    M -->|tools/portfolio_gen| P["🌐 Site portfolio entry<br/>(narrative TODOs for humans)"]
    M -->|scripts/forge.sh| F["🔧 Provisioning<br/>bundle ids · flutterfire ·<br/>icons · checklists"]
    M -->|tools/manifest_validator| V{"validated first,<br/>everywhere"}

    V -.->|"same rule set, imported"| A

    classDef truth fill:#1f4d3b,color:#fff,stroke:#2e7d5f
    class M truth
```

**One rule set:** `tools/manifest_validator` owns the schema rules (and the
tests). The brick's pre_gen hook *imports* it — there is no duplicated
inline copy to drift.

## Section → consumer map

| Manifest section | Key fields | Consumed by |
|---|---|---|
| `identity` | slug, name, tagline, bundle ids | brick (app id, copy), spec_gen, store_gen (name/subtitle), portfolio_gen, forge (rename) |
| `studio` | name, support_email, marketing_site | legal_gen (contact), store_gen (URLs), brick (support copy) |
| `brand` | palette (accent/soft/panel), fonts, logo_mode | brick (theme), spec_gen (§2/§9), portfolio_gen (card palette) |
| `navigation` | tabs (2–5, ≥1 builtin), primary_action | brick (nav_config + stubs + registry), spec_gen (inventory + IDs) |
| `auth` | providers ⊆ {email, apple, google}, guest_mode | brick (sign-in buttons), spec_gen (AUTH screens). Apple auto-included with any social (Guideline 4.8) |
| `monetization` | model, entitlement, trial, products, gates | brick (paywall CTA, entitlement id), spec_gen (gating table), forge (RevenueCat checklist) |
| `features` | remote_config, notifications, cross_promo | brick (dep comments), spec_gen (§7) — *enforcement is Phase 5* |
| `legal` | privacy/terms URLs, data_practices, extras (governing_law, content_summary, domain_disclaimer, extra_providers) | legal_gen (everything), ship_check (ATT when tracking), store_gen (privacy URL) |
| `store` | category, age_rating, keywords, descriptions | store_gen (metadata trees), spec_gen |
| `integrations` | firebase_project, `${REVENUECAT_KEY}` ref | brick (.firebaserc), forge (flutterfire) — **never a literal secret** |

## Validation rules (fail-fast, before anything is generated)

```mermaid
flowchart LR
    m[manifest] --> v["validateManifest()"]
    v --> r1["identity: required fields,<br/>slug is ^[a-z][a-z0-9_]*$"]
    v --> r2["tabs: 2–5, each typed<br/>feature|builtin, ≥1 builtin"]
    v --> r3["auth: ≥1 provider,<br/>only email|apple|google"]
    v --> r4["monetization: model ∈ sub|one_time|hybrid ·<br/>trial-type consistency · ≥1 product"]
    v --> r5["legal: privacy_url + terms_url"]
    v --> r6["integrations.firebase_project"]
    r1 & r2 & r3 & r4 & r5 & r6 --> out{"errors?"}
    out -->|"yes → exit 1, precise list"| stop([nothing generated])
    out -->|no| go([stamp / generate])
```

Trial-type consistency worth remembering: `subscription` can't use
`app_gated` (the store owns subscription trials) and `one_time` can't use
`store_intro_offer` (there's no subscription to attach it to).

## Changing a manifest later

| Changed | Then run |
|---|---|
| Store copy (descriptions, keywords) | `store_gen` — regenerates metadata; never edit the txt files |
| Data practices / legal fields | `legal_gen` → recopy `legal.json` to the site → `npm run build:legal` |
| Palette / fonts | re-stamp or hand-apply to `app.dart` theme block |
| Tabs / gates | re-stamp into a scratch dir and diff — nav wiring is generated |

> **🔲 TODO (future):** no `daedalus update` command exists — applying
> manifest changes to an already-built app is a manual diff today. Parked in
> [Future systems](future.md#parking-lot).
