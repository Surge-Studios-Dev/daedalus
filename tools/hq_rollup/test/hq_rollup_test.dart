import 'package:hq_rollup/hq_rollup.dart';
import 'package:test/test.dart';

void main() {
  test('parses spend CSV with header, comments, and accumulation', () {
    final spend = parseSpendCsv('''
app,channel,amount_usd
# July push
ladle,apple_search_ads,120.50
ladle,meta,79.50
takeoff,apple_search_ads,40
''');
    expect(spend['ladle'], 200.0);
    expect(spend['takeoff'], 40.0);
  });

  test('rejects malformed spend rows instead of dropping money', () {
    expect(() => parseSpendCsv('ladle,meta\n'), throwsFormatException);
    expect(
      () => parseSpendCsv('ladle,meta,not_a_number\n'),
      throwsFormatException,
    );
  });

  test('rolls up spend vs revenue per month across apps', () {
    final data = rollup(
      apps: ['ladle', 'takeoff'],
      spendByMonth: {
        '2026-06': {'ladle': 150.0},
      },
      kpisByApp: {
        'ladle': {
          '2026-06': {'revenue_usd': 480, 'active_users': 310, 'trials': 42},
          '2026-07': {'revenue_usd': 610, 'active_users': 355, 'trials': 51},
        },
      },
    );

    // Months from either source appear, sorted.
    expect(data.keys.toList(), ['2026-06', '2026-07']);
    final june = data['2026-06']!;
    expect(june['ladle']!.revenueUsd, 480);
    expect(june['ladle']!.spendUsd, 150);
    expect(june['takeoff']!.revenueUsd, 0); // registered app, no data yet
    // Portfolio totals: revenue 480, spend 150 -> net 330.
    final rev = june.values.fold(0.0, (s, a) => s + a.revenueUsd);
    final spend = june.values.fold(0.0, (s, a) => s + a.spendUsd);
    expect(rev - spend, 330);
  });

  test('dashboard renders totals, per-app rows, and net coloring', () {
    final html = renderDashboard(
      rollup(
        apps: ['ladle'],
        spendByMonth: {
          '2026-06': {'ladle': 150.0},
        },
        kpisByApp: {
          'ladle': {
            '2026-06': {'revenue_usd': 480, 'active_users': 310, 'trials': 42},
          },
        },
      ),
      generatedOn: '2026-07-01',
    );

    expect(html, contains('revenue \$480'));
    expect(html, contains('spend \$150'));
    expect(html, contains('net \$330'));
    expect(html, contains('class="net pos"'));
    expect(html, contains('<td>ladle</td>'));
    // Self-contained: no external scripts or stylesheets.
    expect(html, isNot(contains('<script src')));
    expect(html, isNot(contains('link rel')));
  });
}
