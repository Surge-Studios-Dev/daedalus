// SEAM: the corpus harness's one per-app function. Run [item] through the
// real pipeline (call the compiled extraction directly, not the deployed
// callable - the corpus measures the pipeline, not the network) and return
// a flat result object for scoring:
//
//   { ok: true, title: "...", ingredients: [...], kcal: 512, ... }
//   { ok: false, error: "fetch_failed" }
//
// Tips from Ladle's harness (see corpus/README.md):
//  - Cache external fetches (oEmbed responses, HTML) on disk keyed by URL
//    hash so re-runs are free and deterministic; add a --no-cache escape.
//  - Return error STRINGS that bucket well ("fetch_failed", "unsupported",
//    "thin_source") - the summary groups failures by them.
export async function runItem(item) {
  void item;
  throw new Error(
    "wire corpus/run_item.mjs to your pipeline (see corpus/README.md)",
  );
}
