# surge_share

The growth rail — a **Tier 3 System** (see [`../../FRAMEWORK.md`](../../FRAMEWORK.md)),
extracted from Ladle's sharing/referrals sprint. Design contract and doctrine:
[`../../SHARING.md`](../../SHARING.md). Two loops:

- **Referral loop (universal, default-on):** invite link → both sides earn
  entitlement-credit days. Needs zero domain knowledge; stamps into every app.
- **Content loop (per-app):** share a domain object as a self-hosted link that
  unfurls into a branded card. The app supplies a snapshot + card layout; the
  rail supplies ids, links, choreography, capture, and referral attribution.

## Use it

```dart
import 'package:surge_share/surge_share.dart';

// Seam pattern, same as AuthService / PurchaseService: mock out of the box,
// a thin Firebase-callables ShareBackend in bootstrap when useFirebase flips.
final service = ShareService(MockShareBackend(), onEvent: analytics.track);
final links = ShareLinks(const String.fromEnvironment(
  'SHARE_LINK_BASE',
  defaultValue: 'https://<app>-app.web.app',
));

// Share: mint the id FIRST so the link exists the instant the user taps.
final id = newLocalShareId();
final link = links.shareLink(id);
// hand `link` to the system share sheet now; create in the background:
final created = await service.createShare(
  type: 'counter',
  title: counter.shareTitle,
  items: [counter.toShareSnapshot()],
  shareId: id,
);

// Branded card (optional, best-effort): capture BEFORE the sheet opens,
// precache every image the card draws first, force light tokens.
final png = await captureShareCardPng(context, card, exportTheme: lightTheme);
if (png != null) await service.attachCard(id, png);

// Receiver side: auto-redeem the referral carried on the share.
final view = await service.getShare(id);
if (view != null) await service.autoRedeem(view.ref);

// Boot: drain banked credit into store grants, one chunk per claim.
final claimer = CreditClaimer(
  claim: service.claimCredit,
  onGranted: (days) {/* refresh customer info + toast */},
);
// call claimer.notify(status.creditDays) on every referral-doc emission
```

## What the mock enforces

`MockShareBackend` applies the same rules as the real server so the whole
flow works on a fresh stamp and tests need no mocks-of-mocks: create-only ids
(collision refused), revoked shares read as gone, one redemption per account,
no self-redeem, reward caps, and chunked credit claims refused while entitled.

## Status

v0.1.0 — links, models, choreography, referral/credit client, capture
harness; all tested on the mock. Not yet wired: the foundation reference
integration and the brick's generalized `backend/sharing/` scaffold
(ROADMAP.md Phase 5a). The capture harness is device-proven in Ladle; the
economy needs a Phase 4 live RevenueCat run.
