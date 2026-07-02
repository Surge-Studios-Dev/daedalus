import 'dart:convert';
import 'dart:io';

import 'package:hq_rollup/hq_rollup.dart';
import 'package:yaml/yaml.dart';

/// CLI: `dart run hq_rollup <hqDir> [--kpis=path.json] [--date=YYYY-MM-DD]`.
///
/// Reads <hqDir>/portfolio.yaml + <hqDir>/spend/YYYY-MM.csv, merges the KPI
/// file (default <hqDir>/fixtures/kpis.json - live PostHog/RevenueCat pulls
/// land at Phase 4+ and write the same shape), writes <hqDir>/dashboard.html.
Future<void> main(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.isEmpty) {
    stderr.writeln(
        'usage: dart run hq_rollup <hqDir> [--kpis=path.json] [--date=...]');
    exit(2);
  }
  final hq = positional[0].replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');

  final portfolioFile = File('$hq/portfolio.yaml');
  if (!portfolioFile.existsSync()) {
    stderr.writeln('Not found: $hq/portfolio.yaml');
    exit(2);
  }
  final portfolio = loadYaml(portfolioFile.readAsStringSync()) as Map;
  final apps = [
    for (final a in (portfolio['apps'] as List? ?? const []))
      '${(a as Map)['slug']}',
  ];

  final kpisFlag = args.firstWhere(
    (a) => a.startsWith('--kpis='),
    orElse: () => '--kpis=$hq/fixtures/kpis.json',
  );
  final kpisPath = kpisFlag.substring('--kpis='.length);
  final kpisRaw = File(kpisPath).existsSync()
      ? jsonDecode(File(kpisPath).readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};
  final kpis = {
    for (final app in kpisRaw.entries)
      app.key: {
        for (final month in (app.value as Map<String, dynamic>).entries)
          month.key: {
            for (final kv in (month.value as Map<String, dynamic>).entries)
              kv.key: kv.value as num,
          },
      },
  };

  final spendByMonth = <String, Map<String, double>>{};
  final spendDir = Directory('$hq/spend');
  if (spendDir.existsSync()) {
    for (final f in spendDir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      final m = RegExp(r'^(\d{4}-\d{2})\.csv$').firstMatch(name);
      if (m == null) continue;
      spendByMonth[m.group(1)!] = parseSpendCsv(f.readAsStringSync());
    }
  }

  final dateFlag = args.firstWhere(
    (a) => a.startsWith('--date='),
    orElse: () => '',
  );
  final date = dateFlag.isNotEmpty
      ? dateFlag.substring('--date='.length)
      : DateTime.now().toIso8601String().substring(0, 10);

  final data = rollup(apps: apps, spendByMonth: spendByMonth, kpisByApp: kpis);
  final html = renderDashboard(data, generatedOn: date);
  File('$hq/dashboard.html').writeAsStringSync(html);
  stdout.writeln('Wrote $hq/dashboard.html '
      '(${data.length} months x ${apps.length} apps). Open it in a browser.');
  if (kpisRaw.isEmpty) {
    stdout.writeln('note: no KPI data found at $kpisPath - revenue/users are '
        'zero. Live PostHog/RevenueCat pulls arrive with Phase 4; until then '
        'fixtures or manual entries drive that side.');
  }
}
