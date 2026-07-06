/// The callable seam between the share rail and the cloud. Same swap pattern
/// as AuthService / PurchaseService: [MockShareBackend] out of the box, a
/// thin Firebase-callables implementation in the app when `useFirebase`
/// flips. Methods return raw wire maps; `ShareService` owns parsing and
/// choreography.
///
/// The server side of this contract is the brick's `backend/sharing/`
/// scaffold (Phase 5a): all share reads/writes go through Cloud Functions —
/// `shares` and `referral_codes` are locked server-only; only
/// `referrals/{uid}` is owner-readable.
abstract interface class ShareBackend {
  /// Create a share doc. Payload: `type`, `title`, `items` (sanitized
  /// snapshots, inline heroes already stripped — the doc goes up LIGHT),
  /// optional pregenerated `shareId`, optional `cardPngBase64`.
  ///
  /// Must be create-only server-side: a colliding id is refused
  /// ([ShareBackendException] `already-exists`), never overwritten.
  Future<Map<String, dynamic>> createShare(Map<String, dynamic> payload);

  /// Fetch a share for the receiver preview. `{ok: false}` when the share is
  /// gone (revoked or never existed).
  Future<Map<String, dynamic>> getShare(String shareId);

  /// Upload the branded card for an already-created share; the link's
  /// unfurl (og:image) picks it up. Attach-before-create is a not-found.
  Future<void> attachShareCard(String shareId, String cardPngBase64);

  /// Uplink one stripped inline hero for the item at [index].
  Future<void> attachShareImage(String shareId, int index, String imageDataUri);

  Future<void> revokeShare(String shareId);

  /// Fire-and-forget saves counter bump; never load-bearing.
  Future<void> recordShareSave(String shareId);

  /// Get-or-create the caller's referral record (code included).
  Future<Map<String, dynamic>> getReferralStatus();

  /// Redeem an invite code. Throws [ShareBackendException] with an expected
  /// code (`not-found`, `own-code`, `already-redeemed`, `account-too-old`)
  /// on the server's gatekeeping rules.
  Future<Map<String, dynamic>> redeemReferral(String code);

  /// Convert banked credit days into a store grant, one chunk per call
  /// (grants REPLACE, not stack — the client re-claims on boot until the
  /// bank drains). Returns granted days; 0 while a paid subscription is
  /// active (credit stays banked as lapse credit).
  Future<int> claimEntitlementCredit();
}

/// Expected, code-carrying rejection from the share backend. Server
/// gatekeeping (one redemption per account, no self-redeem, collisions) is
/// an outcome, not a crash.
class ShareBackendException implements Exception {
  const ShareBackendException(this.code, [this.message = '']);

  final String code;
  final String message;

  @override
  String toString() =>
      'ShareBackendException($code${message.isEmpty ? '' : ': $message'})';
}

/// In-memory backend enforcing the same rules as the real server, so a
/// fresh stamp exercises the whole flow with no cloud and tests need no
/// mocks-of-mocks.
class MockShareBackend implements ShareBackend {
  MockShareBackend({
    this.uid = 'local',
    this.rewardPerReferral = 7,
    this.rewardCap = 90,
    this.grantChunkDays = 30,
    this.maxItems = 50,
    ShareLinksBuilder? links,
  }) : _links = links ?? _defaultLinks;

  /// The signed-in user the mock acts as.
  String uid;

  /// The reward table (a config doc server-side; constructor args here).
  final int rewardPerReferral;
  final int rewardCap;
  final int grantChunkDays;
  final int maxItems;

  /// True simulates an active paid subscription: claims are refused and
  /// credit stays banked (the win-back case).
  bool entitled = false;

  final ShareLinksBuilder _links;
  static String _defaultLinks(String shareId) =>
      'https://mock.web.app/s/$shareId';

  final shares = <String, MockShare>{};
  final referrals = <String, MockReferral>{};
  var _mintCounter = 0;

  MockReferral _referral(String forUid) => referrals.putIfAbsent(
        forUid,
        () => MockReferral(code: 'code-$forUid'),
      );

  @override
  Future<Map<String, dynamic>> createShare(
    Map<String, dynamic> payload,
  ) async {
    final id =
        (payload['shareId'] as String?) ?? 'mock-share-${++_mintCounter}';
    if (shares.containsKey(id)) {
      // A reused id must not overwrite someone's share.
      throw const ShareBackendException('already-exists');
    }
    final items = [
      for (final item in (payload['items'] as List? ?? const []))
        if (item is Map) Map<String, dynamic>.from(item),
    ];
    final dropped = items.length > maxItems ? items.length - maxItems : 0;
    shares[id] = MockShare(
      ownerUid: uid,
      type: payload['type'] as String? ?? '',
      title: payload['title'] as String? ?? '',
      ref: _referral(uid).code,
      items: items.take(maxItems).toList(),
      cardPngBase64: payload['cardPngBase64'] as String?,
    );
    return {'shareId': id, 'link': _links(id), 'droppedItems': dropped};
  }

  @override
  Future<Map<String, dynamic>> getShare(String shareId) async {
    final share = shares[shareId];
    if (share == null || share.revoked) return {'ok': false};
    share.views++;
    return {
      'ok': true,
      'share': {
        'shareId': shareId,
        'type': share.type,
        'ownerName': share.ownerName,
        'ref': share.ref,
        'title': share.title,
        'items': share.items,
      },
    };
  }

  @override
  Future<void> attachShareCard(String shareId, String cardPngBase64) async {
    final share = shares[shareId];
    if (share == null) throw const ShareBackendException('not-found');
    share.cardPngBase64 = cardPngBase64;
  }

  @override
  Future<void> attachShareImage(
    String shareId,
    int index,
    String imageDataUri,
  ) async {
    final share = shares[shareId];
    if (share == null) throw const ShareBackendException('not-found');
    if (index >= 0 && index < share.items.length) {
      share.items[index]['image'] = imageDataUri;
    }
  }

  @override
  Future<void> revokeShare(String shareId) async {
    shares[shareId]?.revoked = true;
  }

  @override
  Future<void> recordShareSave(String shareId) async {
    shares[shareId]?.saves++;
  }

  @override
  Future<Map<String, dynamic>> getReferralStatus() async {
    final r = _referral(uid);
    return {
      'code': r.code,
      'inviteLink': 'https://mock.web.app/i/${r.code}',
      'lifetimeReferrals': r.lifetimeReferrals,
      'creditDays': r.creditDays,
      'redeemedCode': r.redeemedCode,
      'extras': r.extras,
    };
  }

  @override
  Future<Map<String, dynamic>> redeemReferral(String code) async {
    final me = _referral(uid);
    if (me.redeemedCode) {
      throw const ShareBackendException('already-redeemed');
    }
    if (code == me.code) throw const ShareBackendException('own-code');
    MockReferral? inviter;
    for (final r in referrals.values) {
      if (r.code == code) {
        inviter = r;
        break;
      }
    }
    if (inviter == null) throw const ShareBackendException('not-found');
    me.redeemedCode = true;
    inviter.lifetimeReferrals++;
    // The server computes rewards; the client never does. Cap is lifetime.
    final headroom = rewardCap - inviter.grantedLifetime;
    final grant = rewardPerReferral.clamp(0, headroom < 0 ? 0 : headroom);
    inviter.creditDays += grant;
    inviter.grantedLifetime += grant;
    me.creditDays += rewardPerReferral;
    me.grantedLifetime += rewardPerReferral;
    return {'creditDays': rewardPerReferral};
  }

  @override
  Future<int> claimEntitlementCredit() async {
    final r = _referral(uid);
    // Refuse while a paid subscription is active; the credit stays banked
    // (lapse credit doubles as win-back).
    if (entitled || r.creditDays < 1) return 0;
    final granted = r.creditDays.clamp(0, grantChunkDays);
    r.creditDays -= granted;
    return granted;
  }
}

typedef ShareLinksBuilder = String Function(String shareId);

class MockShare {
  MockShare({
    required this.ownerUid,
    required this.type,
    required this.title,
    required this.ref,
    required this.items,
    this.cardPngBase64,
  });

  final String ownerUid;
  final String type;
  final String title;
  final String ref;
  final List<Map<String, dynamic>> items;
  String ownerName = 'a friend';
  String? cardPngBase64;
  bool revoked = false;
  int views = 0;
  int saves = 0;
}

class MockReferral {
  MockReferral({required this.code});

  final String code;
  int lifetimeReferrals = 0;
  int creditDays = 0;
  int grantedLifetime = 0;
  bool redeemedCode = false;
  final extras = <String, int>{};
}
