import 'package:portfolio_gen/portfolio_gen.dart';
import 'package:test/test.dart';

void main() {
  test('seeds derivable fields and rgba palette from the manifest', () {
    final entry = portfolioEntry({
      'identity': {'slug': 'ladle', 'name': 'Ladle', 'tagline': 'Any recipe, one plan.'},
      'brand': {
        'palette': {'accent': '#1F4D3B', 'accent_soft': '#2E7D5F', 'panel': '#0E1B27'},
        'logo_mode': 'wordmark',
      },
      'store': {'full_description': 'Save recipes and turn them into a plan.'},
    });

    expect(entry, contains('id: "ladle"'));
    expect(entry, contains('name: "Ladle"'));
    expect(entry, contains('accent: "#1F4D3B"'));
    // #1F4D3B -> 31, 77, 59
    expect(entry, contains('rgba(31, 77, 59, 0.24)'));
    expect(entry, contains('Save recipes and turn them into a plan.'));
    expect(entry, contains('TODO')); // narrative placeholders present
  });
}
