// Unit tests for the pure sharing layer - no emulator, no mocks. The
// Firestore-touching paths (shares.ts, referrals.ts) are covered by the
// rules tests plus Ladle's live implementation this scaffold was extracted
// from; what lives here is every pure decision the economy and the trust
// boundary make.
import assert from "node:assert/strict";

import {
  canonicalCode,
  newReferralCode,
  newShareId,
  randomCode,
} from "../../lib/sharing/codes.js";
import {
  buildInviteLink,
  buildShareLink,
  linkBase,
} from "../../lib/sharing/links.js";
import {
  DEFAULT_REWARD_CONFIG,
  mergeRewardConfig,
  rewardForReferral,
} from "../../lib/sharing/rewards.js";
import { sanitizeSnapshot } from "../../lib/sharing/sanitize.js";
import { parseDataUri } from "../../lib/sharing/storage.js";
import { bestChunk } from "../../lib/sharing/revenuecat.js";
import { esc } from "../../lib/sharing/web.js";

describe("codes", () => {
  it("share ids are 12 lowercase chars from the unambiguous alphabet", () => {
    for (let i = 0; i < 100; i++) {
      const id = newShareId();
      assert.match(id, /^[a-hj-km-np-z2-9]{12}$/);
      assert.doesNotMatch(id, /[01oil]/);
    }
  });

  it("referral codes carry a typable prefix with lookalikes stripped", () => {
    assert.match(newReferralCode("Max"), /^MAX-[A-HJ-KM-NP-Z2-9]{4}$/);
    // O/I/L are mapped out of the prefix (Eli -> E), padded with SRG.
    assert.match(newReferralCode("Eli"), /^ESR-/);
    assert.match(newReferralCode("Oli"), /^SRG-/);
    assert.match(newReferralCode(undefined), /^SRG-/);
    assert.match(newReferralCode("下雨"), /^SRG-/);
  });

  it("canonicalCode collapses formatting variants to one key", () => {
    for (const variant of ["eli-4f2k", "ELI 4F2K", "Eli.4F2K", "ELI-4F2K"]) {
      assert.equal(canonicalCode(variant), "ELI4F2K");
    }
  });

  it("randomCode never emits lookalike chars", () => {
    assert.doesNotMatch(randomCode(500), /[01OIL]/);
  });
});

describe("links", () => {
  const saved = process.env.SHARE_LINK_BASE;
  afterEach(() => {
    if (saved === undefined) delete process.env.SHARE_LINK_BASE;
    else process.env.SHARE_LINK_BASE = saved;
  });

  it("SHARE_LINK_BASE overrides the default host, trailing slash trimmed", () => {
    process.env.SHARE_LINK_BASE = "https://go.example.app/";
    assert.equal(linkBase(), "https://go.example.app");
    assert.equal(buildShareLink("abc"), "https://go.example.app/s/abc");
    assert.equal(
      buildShareLink("abc", "ELI4F2K"),
      "https://go.example.app/s/abc?ref=ELI4F2K",
    );
    assert.equal(buildInviteLink("ELI4F2K"), "https://go.example.app/i/ELI4F2K");
  });
});

describe("reward economy (config-doc tunable)", () => {
  it("pays per referral until the lifetime cap clamps", () => {
    const cfg = { inviteeDays: 7, perReferralDays: 7, capDays: 10 };
    assert.equal(rewardForReferral(0, cfg), 7);
    assert.equal(rewardForReferral(7, cfg), 3); // clamped, not split
    assert.equal(rewardForReferral(10, cfg), 0); // capped out
    assert.equal(rewardForReferral(999, cfg), 0);
  });

  it("junk lifetime values read as zero earned", () => {
    assert.equal(rewardForReferral(NaN), DEFAULT_REWARD_CONFIG.perReferralDays);
    assert.equal(rewardForReferral(-5), DEFAULT_REWARD_CONFIG.perReferralDays);
  });

  it("mergeRewardConfig takes valid overrides and ignores junk", () => {
    const merged = mergeRewardConfig({
      inviteeDays: 3,
      perReferralDays: "lots",
      capDays: -1,
      unknown: 99,
    });
    assert.equal(merged.inviteeDays, 3);
    assert.equal(merged.perReferralDays, DEFAULT_REWARD_CONFIG.perReferralDays);
    assert.equal(merged.capDays, DEFAULT_REWARD_CONFIG.capDays);
    assert.equal("unknown" in merged, false);
    assert.deepEqual(mergeRewardConfig(null), DEFAULT_REWARD_CONFIG);
    assert.deepEqual(mergeRewardConfig("junk"), DEFAULT_REWARD_CONFIG);
  });
});

describe("sanitize (the trust boundary)", () => {
  it("rebuilds values with caps: strings, numbers, arrays, depth", () => {
    const snap = sanitizeSnapshot({
      title: "  padded  ",
      qty: Infinity,
      big: 1e12,
      list: Array.from({ length: 500 }, (_, i) => i),
      nested: { a: { b: { c: { d: { e: "too deep" } } } } },
      fn: () => "dropped",
    });
    assert.equal(snap.title, "padded");
    assert.equal(snap.qty, 0); // non-finite -> 0
    assert.equal(snap.big, 1e9); // clamped
    assert.equal(snap.list.length, 150);
    assert.equal("fn" in snap, false);
  });

  it("rejects non-objects and oversized payloads", () => {
    assert.equal(sanitizeSnapshot(null), null);
    assert.equal(sanitizeSnapshot("string"), null);
    assert.equal(sanitizeSnapshot([1, 2, 3]), null);
    const bloated = {};
    for (let i = 0; i < 40; i++) bloated[`k${i}`] = "x".repeat(2000);
    assert.equal(sanitizeSnapshot(bloated), null);
  });

  it("image field: data URIs pass untrimmed, URLs capped, junk blanked", () => {
    const dataUri = `data:image/jpeg;base64,${"A".repeat(5000)}`;
    assert.equal(sanitizeSnapshot({ image: dataUri }).image, dataUri);
    assert.equal(
      sanitizeSnapshot({ image: "https://cdn/x.jpg" }).image,
      "https://cdn/x.jpg",
    );
    assert.equal(sanitizeSnapshot({ image: "javascript:alert(1)" }).image, "");
    assert.equal(sanitizeSnapshot({ image: 42 }).image, "");
    assert.equal(
      sanitizeSnapshot({ image: `https://cdn/${"x".repeat(3000)}` }).image,
      "",
    );
  });
});

describe("storage parseDataUri", () => {
  it("parses base64 data URIs and rejects everything else", () => {
    const parsed = parseDataUri("data:image/png;base64,aGVsbG8=");
    assert.equal(parsed.mime, "image/png");
    assert.equal(parsed.bytes.toString(), "hello");
    assert.equal(parseDataUri("https://x/y.png"), null);
    assert.equal(parseDataUri("data:image/png;base64,"), null);
    assert.equal(parseDataUri("data:;base64,aGk=").mime, "image/jpeg");
  });
});

describe("revenuecat chunking (grants replace, not stack)", () => {
  it("picks the largest chunk that fits and drains the tail", () => {
    assert.equal(bestChunk(400).days, 365);
    assert.equal(bestChunk(90).days, 90);
    assert.equal(bestChunk(70).days, 60);
    assert.equal(bestChunk(6).days, 3);
    assert.equal(bestChunk(1).days, 1);
    assert.equal(bestChunk(0), null);
  });
});

describe("web esc()", () => {
  it("escapes every HTML-significant char in user strings", () => {
    assert.equal(
      esc(`<img src="x" onerror='pwn'>&`),
      "&lt;img src=&quot;x&quot; onerror=&#39;pwn&#39;&gt;&amp;",
    );
    assert.equal(esc(undefined), "");
  });
});
