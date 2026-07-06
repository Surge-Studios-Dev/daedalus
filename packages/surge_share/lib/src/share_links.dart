import 'dart:math';

/// Self-hosted share links (SHARING.md: "don't buy link infrastructure").
///
/// Ids are minted ON DEVICE so the link exists the instant the user taps
/// Share — the system sheet opens immediately while createShare uploads the
/// snapshot in the background. The server accepts the pregenerated id and
/// refuses collisions with an existing doc (`create()`, never `set()`).
///
/// [base] is the active link domain, switched by env/bootstrap — never a
/// constant — and the app's original `*.web.app` host must stay registered
/// in entitlements/intent filters forever: old links were minted on it.
class ShareLinks {
  const ShareLinks(this.base);

  /// e.g. `https://go.tally.app` or `https://tally-app.web.app`. No trailing
  /// slash.
  final String base;

  String shareLink(String shareId) => '$base/s/$shareId';
  String inviteLink(String code) => '$base/i/$code';

  /// Stable og:image URL, decided at mint time; the backend endpoint waits
  /// for the card artifact and degrades (hero redirect -> 404).
  String cardImageUrl(String shareId) => '$base/c/$shareId.png';
}

// Same unambiguous alphabet as the backend (no 0/O/1/I/L lookalikes),
// lowercased: 12 chars ~= 59 bits — a collision is the server's create()
// guard's problem, not a realistic event.
const shareIdAlphabet = 'abcdefghjkmnpqrstuvwxyz23456789';
const shareIdLength = 12;
final _random = Random.secure();

/// Mint a share id locally. Pair it with the server's collision-refusing
/// `create()` — a reused id must not overwrite someone's share.
String newLocalShareId() {
  return List.generate(
    shareIdLength,
    (_) => shareIdAlphabet[_random.nextInt(shareIdAlphabet.length)],
  ).join();
}
