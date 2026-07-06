import 'package:flutter_test/flutter_test.dart';
import 'package:surge_share/surge_share.dart';

void main() {
  test('minted ids are 12 chars from the unambiguous alphabet', () {
    for (var i = 0; i < 200; i++) {
      final id = newLocalShareId();
      expect(id.length, shareIdLength);
      for (final char in id.split('')) {
        expect(
          shareIdAlphabet.contains(char),
          isTrue,
          reason: 'bad char $char',
        );
      }
      // The lookalike set must never appear.
      expect(RegExp('[01oil]').hasMatch(id), isFalse);
    }
  });

  test('mints are distinct', () {
    final ids = {for (var i = 0; i < 500; i++) newLocalShareId()};
    expect(ids.length, 500);
  });

  test('links are built off the configured base', () {
    const links = ShareLinks('https://go.tally.app');
    expect(links.shareLink('abc'), 'https://go.tally.app/s/abc');
    expect(links.inviteLink('code-x'), 'https://go.tally.app/i/code-x');
    expect(links.cardImageUrl('abc'), 'https://go.tally.app/c/abc.png');
  });
}
