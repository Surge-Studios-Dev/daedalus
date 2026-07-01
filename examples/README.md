# examples

- `ladle.manifest.yaml` + `ladle/` — **real product** (Ladle, a Surge Studios
  app). Its generated legal lives on the marketing site
  (`Surge-Studios-Site/src/content/legal/ladle.json`).
- `tally/` — generated output for **"Tally", a fictional demo app** used by
  `surge.manifest.example.yaml` to exercise every schema field. Not a Surge
  product; never register it on the site or in the portfolio.

Regenerate either with `dart run bin/legal_gen.dart <manifest> <outdir>` from
`tools/legal_gen`.
