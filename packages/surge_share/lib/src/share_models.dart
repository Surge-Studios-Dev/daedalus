/// Transport shapes for the sharing + referral callables. Plain Dart, no
/// codegen: these are thin wire types; the app converts item maps into its
/// own domain models.
library;

/// What an app must supply to make a domain object shareable. The rail owns
/// links, docs, cards, and referrals; the app owns what a "recipe" or
/// "counter" is.
abstract interface class Shareable {
  /// Snake_case type id, matching the manifest's `sharing.content` list.
  String get shareType;

  /// User-facing title for the share (card headline, unfurl title).
  String get shareTitle;

  /// Sanitized snapshot: personal fields stripped BEFORE the bytes leave the
  /// device (the server strips again — belt and braces plus a smaller
  /// payload). Inline `data:` images are allowed here; the service strips
  /// and re-attaches them so the doc goes up light.
  Map<String, dynamic> toShareSnapshot();
}

/// Result of createShare: the minted link plus honesty about any items a
/// too-big bundle had to drop.
class CreatedShare {
  const CreatedShare({
    required this.shareId,
    required this.link,
    this.droppedItems = 0,
  });

  final String shareId;
  final String link;
  final int droppedItems;

  factory CreatedShare.fromJson(Map<String, dynamic> json) => CreatedShare(
        shareId: json['shareId'] as String? ?? '',
        link: json['link'] as String? ?? '',
        droppedItems: (json['droppedItems'] as num?)?.toInt() ?? 0,
      );
}

/// A share as the receiver sees it. [items] holds one snapshot map for a
/// single-item share and the full bundle for a collection share; the app
/// rehydrates them into domain models (fresh local ids, zeroed personal
/// fields).
class ShareView {
  const ShareView({
    required this.shareId,
    required this.type,
    required this.ownerName,
    required this.ref,
    required this.title,
    required this.items,
  });

  final String shareId;
  final String type;
  final String ownerName;

  /// Sharer's referral code, carried on every share so the receiving app can
  /// auto-redeem it (attribution is code-based, not SDK-based).
  final String ref;
  final String title;
  final List<Map<String, dynamic>> items;

  factory ShareView.fromJson(Map<String, dynamic> json) => ShareView(
        shareId: json['shareId'] as String? ?? '',
        type: json['type'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        ref: json['ref'] as String? ?? '',
        title: json['title'] as String? ?? '',
        items: [
          for (final item in (json['items'] as List? ?? const []))
            if (item is Map) Map<String, dynamic>.from(item),
        ],
      );
}

/// The caller's referral standing (`referrals/{uid}`, owner-read only —
/// money-shaped state lives in server-only collections).
class ReferralStatus {
  const ReferralStatus({
    required this.code,
    this.inviteLink = '',
    this.lifetimeReferrals = 0,
    this.creditDays = 0,
    this.redeemedCode = false,
    this.extras = const {},
  });

  final String code;

  /// Built server-side; only the callable carries it (a Firestore doc stream
  /// leaves it empty).
  final String inviteLink;
  final int lifetimeReferrals;

  /// Banked entitlement-credit days not yet converted into a store grant.
  /// Drained one chunk per claim (grants replace, not stack).
  final int creditDays;

  /// True once this account has redeemed someone else's code (one per
  /// account, enforced server-side).
  final bool redeemedCode;

  /// App-specific reward counters (e.g. Ladle's banked imports) — the rail
  /// carries them opaquely.
  final Map<String, int> extras;

  factory ReferralStatus.fromJson(Map<String, dynamic> json) => ReferralStatus(
        code: json['code'] as String? ?? '',
        inviteLink: json['inviteLink'] as String? ?? '',
        lifetimeReferrals: (json['lifetimeReferrals'] as num?)?.toInt() ?? 0,
        creditDays: (json['creditDays'] as num?)?.toInt() ?? 0,
        redeemedCode: json['redeemedCode'] == true ||
            (json['referredBy'] is String &&
                (json['referredBy'] as String).isNotEmpty),
        extras: {
          for (final entry in (json['extras'] as Map? ?? const {}).entries)
            if (entry.value is num)
              '${entry.key}': (entry.value as num).toInt(),
        },
      );
}
