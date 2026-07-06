# SHARING.md · The growth rail (sharing + referrals)

Every Surge app grows by word of mouth or not at all — paid acquisition is a
Phase-5 experiment, not the plan. So sharing is universal infrastructure, not a
per-app feature. This doc is the design contract for the growth rail; the
transferable rules were extracted from Ladle's 2026-07-02 sharing sprint
(`Ladle/DAEDALUS-LESSONS.md` is the source document; this file is where those
lessons live going forward).

> **Implementation status (current).** Built and stamp-verified end to end
> (ROADMAP.md Phase 5a): `packages/surge_share` (client, on mocks), the
> brick's `backend/src/sharing/` scaffold (callables + shareLink unfurl
> endpoint + rules, emulator-tested), hosting rewrites + `.well-known`
> deep-link templates, and the foundation's invite card on the settings
> surface. A fresh stamp ships the referral loop working on mocks.
> Remaining for a live app: fill TEAMID/fingerprints in `.well-known`, add
> the Associated Domains entitlement + autoVerify intent filter, set
> `REVENUECAT_SECRET`, and verify grants + link-opening on real devices
> (Phase 4). Per-app content sharing plugs into `Shareable` when the app
> declares `sharing.content`.

## The two loops (only one needs domain knowledge)

1. **The referral loop — universal, default-on.** Invite a friend via a link;
   both sides earn entitlement credit. Needs zero domain knowledge: every
   Surge app already has exactly one entitlement, so "share the app, earn free
   days" stamps identically into a counter app, a recipe app, anything. This
   is the loop that ships in **every** app.
2. **The content loop — on when the app declares it.** Share *a thing* (a
   recipe, a collection) as a link that unfurls into a branded card and lands
   on a save-this-into-your-app page. Only meaningful when the app has
   shareable content; the app supplies a snapshot + card layout, the rail
   supplies everything else.

An app with nothing shareable still grows through loop 1.

## Manifest

```yaml
sharing:
  referrals: true                    # default true; false opts an app out
  reward:                            # required when referrals is true
    type: entitlement_days           # the only type today
    per_referral: 7                  # days granted per successful referral
    cap: 90                          # lifetime cap per account
  link_domain: go.tally.app          # optional custom domain (no scheme);
                                     # the *.web.app default always works
  content: [counter]                 # shareable type ids; omit for referral-only
```

Omitting the whole block means `referrals: true` with the studio-default
reward (7 days, cap 90) and no content sharing. `sharing: { referrals: false }`
opts out entirely (rare; justify it in the spec).

## Architecture (where each piece lives)

| Piece | Tier / home | Contents |
|---|---|---|
| `packages/surge_share` | 3 | Link minting, `ShareService` choreography over a callable seam, referral/credit client, card-capture harness, `Shareable` contract |
| Backend `sharing/` scaffold | brick `__brick__/backend/src/sharing` | codes, shares, referrals, rewards, sanitize (generic structural trust boundary; add a domain sanitizer per app), storage, web (OG card page + stable og:image endpoint), rate limiting — generalized from Ladle, unit + rules tested |
| Deep-link wiring | brick `__brick__/hosting` + firebase.json | `.well-known/apple-app-site-association` + `assetlinks.json` templated from the manifest bundle ids (TEAMID/fingerprints are forge-checklist items), `/s/* /i/* /c/*` rewrites to `shareLink`; the ios/android entitlement + intent filter land at forge time (platform folders are created then) |
| Referral card + code sheet UI | foundation `modules/share` (mirrored into the brick) → promote pieces to `surge_ui` when a second app restyles them | Inline invite card on the settings surface, "Have a code?" sheet, credit-claimer drain |
| Reward config | Firestore config doc merged over code defaults | Tunable economy without an app release |

The service follows the seam pattern (the framework's spine): the package
defines a `ShareBackend` callable seam; `MockShareBackend` ships working (whole
flow runs on a fresh stamp with no cloud); the Firebase implementation is a
thin invoker the app wires in bootstrap when `useFirebase` flips.

## The link doctrine (lesson: don't buy link infrastructure)

Branch-class link SDKs cost ~$15k/yr and add an SDK + privacy-manifest
surface. The self-hosted pattern is ~200 lines and owns everything:

- **Deterministic URLs, no mint API.** `https://<domain>/s/{shareId}` and
  `/i/{code}`. Ids are minted **on device** (12 chars from an unambiguous
  alphabet, ~59 bits) so the link exists the instant the user taps Share. The
  server accepts the pregenerated id and refuses collisions — `create()`,
  never `set()`: a reused id must not overwrite someone's share.
- **Installed** → Universal Links / App Links open the app directly.
- **Not installed** → hosting rewrites the path to one HTTP function that
  renders an OG-tagged web card with store buttons and the invite code.
- **Attribution is code-based, not SDK-based.** The share doc carries the
  sharer's referral code; the receiving app auto-redeems it on open. Manual
  code entry is the fallback. Deferred deep linking is the one thing lost —
  in practice the invitee re-taps the link. Acceptable trade at $0.
- **The zero-DNS `*.web.app` domain works forever.** Old links were minted on
  it. Both hosts stay registered in entitlements/intent filters; the active
  domain is an env var (`SHARE_LINK_BASE`), never a constant.

## The unfurl contract (burn this in)

**Messengers fetch a link's preview exactly once, at send time, per message.**
Everything follows from that:

- A premature 404 breaks that message's preview *forever*; no retry on our
  side can fix it. So the **server waits instead of racing**: if the share doc
  or card image doesn't exist yet, the endpoint polls its own storage for a
  few seconds before answering.
- **Cache-control is a correctness tool.** Only complete, immutable responses
  are cacheable (`public`); every failure and not-ready response is
  `no-store`, or the CDN poisons the link for every fetcher after.
- **og:image is a stable URL** decided at mint time (`/c/{id}.png`), served by
  an endpoint that waits for the real image and degrades (hero redirect →
  404). Never point og:image at a URL that doesn't exist yet.
- **The doc goes up light.** Metadata (title + fallback) first; heavy
  artifacts (card PNG, rehosted heroes) attach afterwards via separate calls.
  A megabytes-scale first payload delays the doc write past the poll window
  on slow uplinks.
- Platform truths you cannot engineer around: iMessage previews render on the
  **sender's** device; Android → iPhone over SMS/RCS is always tap-to-load.
  Know the coverage map before promising "previews everywhere".

## Instant-UX choreography

- Pregenerate the id client-side → the deliverable exists at tap.
- Fire the essential write first, stripped to what the unfurl needs; chain
  heavy attachments behind it (attach-before-create is a not-found).
- Bound every pre-UI await (image warm-up gets a timeout; a dead CDN costs the
  timeout, not the flow — degrade to placeholders).
- Parallelize independent server work; park a no-op `.catch` on any early
  promise a validation throw could orphan.
- Failures own up: if the background create fails after the link was already
  handed to the sheet, say "that link will not work" — never pretend.
- Inline (data:) images belong in Storage, not in Firestore docs or
  latency-bound callable payloads. When a size cap tempts you to *blank* user
  content, rehost instead — blanking is data loss users see immediately.

## Card capture (every trap, once)

`surge_share`'s capture harness encodes these; they are listed so nobody
relearns them:

1. Capture **before** the share sheet opens (the Android activity pauses
   under the system sheet; frame-driven capture stalls).
2. **Image-provider identity IS the cache key.** One memoized provider per
   image string, shared by the precache and the card widget (`MemoryImage`
   keys by bytes identity; `ResizeImage` keys differently than its inner
   provider).
3. Precache every image the card draws — **including bundled assets**.
4. A fixed-size export layout must be overflow-proof: worst-case height math,
   `Flexible` so drift ellipsizes, and a widget test pinning it (an overflow
   in debug paints the yellow banner *into the exported PNG*).
5. Force the export theme (light tokens) on the capture subtree — the card
   must not vary with the sender's theme.
6. Base64-encode off the UI isolate (`compute`) — it lands exactly while the
   share sheet animates.

## Money-shaped state (the referral economy)

Referral credits, banked entitlement days, anything that converts to value:

- Lives in **server-only collections** (`referrals/{uid}` owner-read only),
  never inside a user-writable doc.
- Every mutation goes through a callable that enforces: one redemption per
  account, no self-redeem, account-age gates, rate limits. The client never
  computes rewards.
- Client-supplied snapshots are fine **if** the server re-validates everything
  at a single trust boundary (a sanitize module with hard caps).
- The reward table is a config doc merged over code defaults — tunable
  economy, no release.
- RevenueCat quirk: promotional grants **replace**, not stack. Grant the
  largest fitting chunk per call; the client re-claims on boot until the bank
  drains; refuse grants while a paid subscription is active (accrue as lapse
  credit — doubles as win-back).

The economy is the one piece that cannot be fully verified until a Phase 4
live run (sandbox grants against a real RevenueCat app). Mocks cover the
logic; the live flip is on the Phase 4 checklist.

## The web card page (serving HTML from a function)

- Inline everything (CSS, script); escape every user string before it touches
  HTML.
- Plain block flow with `margin: 0 auto` — never flex-center a
  variable-height card with `min-height: 100vh` (content taller than the
  viewport becomes unreachable).
- **Scale brand imagery, never crop it** (`object-fit: cover` in a height cap
  silently amputates; a square image in a square box shrinks with zero crop).
- The page fits one phone screen with the CTA visible; "scroll to find the
  button" reads as a bug.
- Static one-offs (logos) live on the hosting site as files, referenced
  relatively.

## Telemetry (extends the standard taxonomy)

Standard events, identical across every app so the portfolio dashboard
computes viral coefficient with zero per-app wiring — **never rename**:

`share_create{type}` · `share_open{source}` · `share_save{type}` ·
`referral_redeem` · `reward_grant{days}` · `invite_view`

Apps add domain events on top.

## Ops notes (paid for in round trips)

- The functions `.env` (`SHARE_LINK_BASE`, webhook URLs, API keys) is
  gitignored, which means **the deploy machine is state**. Record env changes
  in the project docs or the next deploy silently reverts behavior.
- Deploy from the directory that owns the `firebase.json` for the target; a
  root config that only knows hosting will **silently skip**
  `--only functions:x`. Watch the deploy output for the function line, not
  just "Deploy complete".
- DNS: in Namecheap's Advanced DNS the Host field wants only the subdomain
  part (`go`), not the FQDN — `go.example.com` in that field creates
  `go.example.com.example.com`. Verify against the authoritative NS, not your
  own resolver cache.
- Immutable published artifacts (cached card PNGs, per-message previews) keep
  showing old bugs after a fix ships. Tell the user "reshare to see it" —
  otherwise the fix looks broken.

## Rollout checklist (per app)

- [ ] `sharing` block in the manifest; reward economy reviewed
- [ ] Client-minted share id; `create()`-only doc write; light doc first,
      heavy artifacts attached after
- [ ] Stable og:image endpoint that polls for the artifact; `no-store` on
      every non-final response; `public` cache only on complete pages
- [ ] Page + getShare both wait briefly for a just-created doc
- [ ] Universal Links + App Links from day one; env-switchable domain; old
      domain kept alive forever
- [ ] Card capture: memoized providers, precache heroes **and assets**,
      overflow-proof fixed layout + widget test, encode off the UI thread,
      capture before the sheet
- [ ] Referral/credit state server-only; sanitize boundary; config-doc reward
      table; grants drain one chunk per claim
- [ ] Web card: block flow, one-screen fit, scale-don't-crop, escape all user
      strings
- [ ] Standard telemetry events wired
- [ ] Verify on the recipient's real device, both directions, both platforms,
      before calling it done
