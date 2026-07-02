/// Surge HQ rollup: one dashboard across every app's analytics.
///
/// Inputs (all under hq/):
///   portfolio.yaml       the app registry (slug, name, status, project ids)
///   spend/YYYY-MM.csv    manual ad-spend entries: app,channel,amount_usd
///                        (ad networks have no free-tier APIs worth wiring;
///                        manual monthly entry first, API pulls parked)
///   kpis JSON            per-app monthly KPIs. Offline mode reads a fixture
///                        file; live mode (Phase 4+) fills the same shape
///                        from the PostHog trends + RevenueCat metrics APIs.
///
/// Output: a single self-contained dashboard.html - monthly total spend vs
/// revenue vs net across the portfolio, plus a per-app breakdown - using
/// pure HTML/CSS bars (no CDN, renders offline forever).
library;

/// One month's numbers for one app.
class AppMonth {
  const AppMonth({
    this.revenueUsd = 0,
    this.spendUsd = 0,
    this.activeUsers = 0,
    this.trials = 0,
  });
  final double revenueUsd;
  final double spendUsd;
  final int activeUsers;
  final int trials;

  AppMonth operator +(AppMonth o) => AppMonth(
        revenueUsd: revenueUsd + o.revenueUsd,
        spendUsd: spendUsd + o.spendUsd,
        activeUsers: activeUsers + o.activeUsers,
        trials: trials + o.trials,
      );
}

/// Parses one spend CSV (header `app,channel,amount_usd`) into per-app spend
/// totals. Blank lines and comment lines (#) are ignored; a malformed row is
/// an error - silently dropping money rows would corrupt the dashboard.
Map<String, double> parseSpendCsv(String content) {
  final spend = <String, double>{};
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (i == 0 && line.toLowerCase().startsWith('app,')) continue; // header
    final parts = line.split(',');
    if (parts.length != 3) {
      throw FormatException('spend row ${i + 1} needs app,channel,amount_usd '
          '(got "$line")');
    }
    final amount = double.tryParse(parts[2].trim());
    if (amount == null) {
      throw FormatException('spend row ${i + 1}: bad amount "${parts[2]}"');
    }
    final app = parts[0].trim();
    spend[app] = (spend[app] ?? 0) + amount;
  }
  return spend;
}

/// Merges the registry, spend-by-month, and KPIs-by-app-by-month into
/// month -> app -> AppMonth. Months present in either source appear.
Map<String, Map<String, AppMonth>> rollup({
  required List<String> apps,
  required Map<String, Map<String, double>> spendByMonth,
  required Map<String, Map<String, Map<String, num>>> kpisByApp,
}) {
  final months = <String>{
    ...spendByMonth.keys,
    for (final byMonth in kpisByApp.values) ...byMonth.keys,
  }.toList()
    ..sort();

  final out = <String, Map<String, AppMonth>>{};
  for (final month in months) {
    final perApp = <String, AppMonth>{};
    for (final app in apps) {
      final k = kpisByApp[app]?[month] ?? const {};
      perApp[app] = AppMonth(
        revenueUsd: (k['revenue_usd'] ?? 0).toDouble(),
        spendUsd: spendByMonth[month]?[app] ?? 0,
        activeUsers: (k['active_users'] ?? 0).toInt(),
        trials: (k['trials'] ?? 0).toInt(),
      );
    }
    out[month] = perApp;
  }
  return out;
}

String _usd(double v) => '\$${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}';

/// Renders the self-contained dashboard. Pure HTML/CSS (bar widths are
/// percentage-scaled divs) so it opens from disk with no network, forever.
String renderDashboard(
  Map<String, Map<String, AppMonth>> data, {
  required String generatedOn,
}) {
  final months = data.keys.toList()..sort();
  final maxBar = [
    for (final m in months) ...[
      data[m]!.values.fold(0.0, (s, a) => s + a.revenueUsd),
      data[m]!.values.fold(0.0, (s, a) => s + a.spendUsd),
    ],
  ].fold(1.0, (a, b) => a > b ? a : b);

  final b = StringBuffer('''
<!doctype html><html><head><meta charset="utf-8">
<title>Surge HQ · portfolio rollup</title>
<style>
  :root { --ink:#0b0d12; --sub:#555d6b; --line:#e6e9ee; --rev:#2e7d5f; --spend:#d8a03d; --neg:#de3b41; }
  body { font: 15px/1.5 system-ui, sans-serif; color: var(--ink); max-width: 960px; margin: 40px auto; padding: 0 20px; }
  h1 { font-size: 26px; } h2 { font-size: 18px; margin-top: 36px; }
  .sub { color: var(--sub); }
  table { border-collapse: collapse; width: 100%; margin: 12px 0; }
  th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid var(--line); font-variant-numeric: tabular-nums; }
  th { color: var(--sub); font-size: 12px; text-transform: uppercase; letter-spacing: .06em; }
  td.num, th.num { text-align: right; }
  .bars { display: grid; gap: 4px; margin: 6px 0 18px; }
  .bar { height: 18px; border-radius: 4px; color: #fff; font-size: 11px; line-height: 18px; padding-left: 6px; white-space: nowrap; }
  .bar.rev { background: var(--rev); } .bar.spend { background: var(--spend); }
  .net.pos { color: var(--rev); font-weight: 600; } .net.neg { color: var(--neg); font-weight: 600; }
</style></head><body>
<h1>Surge HQ · portfolio rollup</h1>
<p class="sub">Generated $generatedOn · revenue from RevenueCat · spend from hq/spend CSVs · KPIs from PostHog</p>
<h2>Monthly: total spend vs revenue</h2>
''');

  for (final m in months) {
    final apps = data[m]!;
    final rev = apps.values.fold(0.0, (s, a) => s + a.revenueUsd);
    final spend = apps.values.fold(0.0, (s, a) => s + a.spendUsd);
    final net = rev - spend;
    b.writeln('<h3>$m <span class="net ${net >= 0 ? 'pos' : 'neg'}">'
        'net ${_usd(net)}</span></h3>');
    b.writeln('<div class="bars">');
    b.writeln('<div class="bar rev" style="width:${(rev / maxBar * 100).clamp(2, 100)}%">revenue ${_usd(rev)}</div>');
    b.writeln('<div class="bar spend" style="width:${(spend / maxBar * 100).clamp(2, 100)}%">spend ${_usd(spend)}</div>');
    b.writeln('</div>');
    b.writeln('<table><tr><th>App</th><th class="num">Revenue</th>'
        '<th class="num">Spend</th><th class="num">Net</th>'
        '<th class="num">Active users</th><th class="num">Trials</th></tr>');
    for (final e in apps.entries) {
      final n = e.value.revenueUsd - e.value.spendUsd;
      b.writeln('<tr><td>${e.key}</td>'
          '<td class="num">${_usd(e.value.revenueUsd)}</td>'
          '<td class="num">${_usd(e.value.spendUsd)}</td>'
          '<td class="num net ${n >= 0 ? 'pos' : 'neg'}">${_usd(n)}</td>'
          '<td class="num">${e.value.activeUsers}</td>'
          '<td class="num">${e.value.trials}</td></tr>');
    }
    b.writeln('</table>');
  }

  b.writeln('</body></html>');
  return b.toString();
}
