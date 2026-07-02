# Surge HQ · portfolio rollup

One dashboard across every app: monthly **total ad spend vs revenue vs net**,
plus per-app KPIs. Studio-level (never stamped into apps).

```bash
# 1. record ad spend for the month (manual until ad-network APIs are wired)
#    -> edit hq/spend/YYYY-MM.csv   (app,channel,amount_usd)
# 2. regenerate
cd tools/hq_rollup && dart run bin/hq_rollup.dart ../../hq
# 3. open hq/dashboard.html
```

KPIs (revenue, active users, trials) come from a JSON file with one shape:
`{app: {YYYY-MM: {revenue_usd, active_users, trials}}}`. Today that file is
`fixtures/kpis.json` (zeroes until launch); at Phase 4+ a live pull from the
PostHog trends + RevenueCat metrics APIs writes the same shape - the
dashboard doesn't change. Registry: `portfolio.yaml` (a transferred client
app keeps its row with `status: transferred`; its PostHog project leaves
with the repo).
