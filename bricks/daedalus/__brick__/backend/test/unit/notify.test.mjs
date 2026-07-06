// Unit tests for the pure notify layer (format.ts) - no emulator, no mocks.
// Run via `npm run test:unit` (they import the compiled lib/, so build first;
// `npm test` sequences that).
import assert from "node:assert/strict";

import {
  classifyRevenueCatEvent,
  formatFeedbackEmbed,
  formatInstallEmbed,
  formatPurchaseEmbed,
  isAuthorized,
  shortUid,
  truncate,
} from "../../lib/notify/format.js";

describe("anonymization", () => {
  it("shortUid keeps 8 chars and never crashes on junk", () => {
    assert.equal(shortUid("abcdefghijkl"), "abcdefgh");
    assert.equal(shortUid(""), "unknown");
    assert.equal(shortUid(undefined), "unknown");
  });

  it("truncate caps free text with the ellipsis inside the cap", () => {
    assert.equal(truncate("short"), "short");
    const capped = truncate("x".repeat(600));
    assert.equal(capped.length, 500);
    assert.ok(capped.endsWith("…"));
  });
});

describe("install embed", () => {
  it("carries the short uid and a valid timestamp", () => {
    const embed = formatInstallEmbed("user1234567", "2026-07-01T10:00:00Z");
    assert.equal(embed.title, "New install");
    assert.equal(embed.fields[0].value, "user1234");
    assert.equal(embed.timestamp, "2026-07-01T10:00:00.000Z");
  });

  it("drops an unparseable creation time instead of crashing", () => {
    const embed = formatInstallEmbed("u", "not-a-date");
    assert.equal(embed.timestamp, undefined);
  });
});

describe("feedback embed (client-written doc is hostile)", () => {
  it("formats a support request and truncates the text", () => {
    const embed = formatFeedbackEmbed(
      { text: "y".repeat(600), platform: "ios", appVersion: "1.2.0" },
      "uid-abcdefgh",
    );
    assert.equal(embed.title, "Support request");
    assert.equal(embed.description.length, 500);
    assert.deepEqual(
      embed.fields.map((f) => f.name),
      ["User", "Platform", "App version"],
    );
  });

  it("tolerates missing and mistyped fields", () => {
    const embed = formatFeedbackEmbed(
      { text: 42, platform: null, appVersion: {} },
      "u",
    );
    assert.equal(embed.description, "(no text)");
    assert.equal(embed.fields.length, 1); // just User
  });

  it("classifies rating-sourced docs as feedback", () => {
    const embed = formatFeedbackEmbed({ text: "5 stars", source: "rating" }, "u");
    assert.equal(embed.title, "Feedback");
  });
});

describe("RevenueCat classification matrix", () => {
  const cases = [
    [{ type: "INITIAL_PURCHASE", period_type: "TRIAL" }, "trial_started"],
    [{ type: "INITIAL_PURCHASE", period_type: "NORMAL" }, "purchase"],
    [{ type: "INITIAL_PURCHASE" }, "purchase"],
    [{ type: "RENEWAL", is_trial_conversion: true }, "trial_converted"],
    [{ type: "RENEWAL" }, null],
    [{ type: "NON_RENEWING_PURCHASE" }, "purchase"],
    [{ type: "TEST" }, "test"],
    [{ type: "CANCELLATION" }, null],
    [{ type: "EXPIRATION" }, null],
    [{ type: "BILLING_ISSUE" }, null],
    [{}, null],
  ];
  for (const [event, expected] of cases) {
    it(`${event.type ?? "(none)"}${event.period_type ? "/" + event.period_type : ""}${event.is_trial_conversion ? "/conv" : ""} -> ${expected}`, () => {
      assert.equal(classifyRevenueCatEvent(event), expected);
    });
  }
});

describe("purchase embed", () => {
  it("prefers purchased-currency price and tags sandbox", () => {
    const embed = formatPurchaseEmbed("trial_started", {
      app_user_id: "uid12345678",
      product_id: "pro_annual",
      price: 19.99,
      price_in_purchased_currency: 21.5,
      currency: "EUR",
      store: "APP_STORE",
      environment: "SANDBOX",
    });
    assert.equal(embed.title, "Trial started [sandbox]");
    const price = embed.fields.find((f) => f.name === "Price");
    assert.equal(price.value, "21.50 EUR");
    const user = embed.fields.find((f) => f.name === "User");
    assert.equal(user.value, "uid12345");
  });
});

describe("webhook auth fails closed", () => {
  it("matches exactly, rejects mismatch and missing header", () => {
    assert.equal(isAuthorized("secret", "secret"), true);
    assert.equal(isAuthorized("wrong", "secret"), false);
    assert.equal(isAuthorized(undefined, "secret"), false);
  });

  it("an UNSET secret rejects everything (unconfigured != open)", () => {
    assert.equal(isAuthorized("anything", undefined), false);
    assert.equal(isAuthorized("anything", ""), false);
    assert.equal(isAuthorized(undefined, undefined), false);
  });
});
