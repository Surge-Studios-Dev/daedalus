import 'dart:async';

import 'package:flutter/foundation.dart';

import 'share_backend.dart';
import 'share_models.dart';

/// The share choreography, encoded once (SHARING.md "instant-UX
/// choreography"): pregenerated ids, the doc goes up light, heavy artifacts
/// attach behind it, every attach is best-effort, failures own up via the
/// returned result — never a stuck share sheet.
class ShareService {
  ShareService(
    this._backend, {
    this.maxItems = 50,
    this.onEvent,
  });

  final ShareBackend _backend;

  /// Mirror of the server's bundle cap: items past it are dropped there, so
  /// there is no point uplinking their art.
  final int maxItems;

  /// Telemetry hook for the standard events (`share_create`, `share_open`,
  /// `share_save`, `referral_redeem`, `reward_grant`). The app binds this to
  /// its Analytics; the rail never renames the base set.
  final void Function(String event, Map<String, Object?> props)? onEvent;

  final _pendingAttachments = <Future<void>>[];

  /// Snapshot [items] into a share. [shareId] should be pregenerated on
  /// device (`newLocalShareId()`) so the caller hands the link to the system
  /// sheet before this round-trip completes.
  ///
  /// Inline `data:` heroes are stripped before the call and uplinked
  /// separately afterward: a multi-megabyte hero inside createShare holds
  /// the doc write hostage to the phone's uplink, and unfurl bots only wait
  /// a few seconds before a missing doc permanently breaks that message's
  /// preview. The doc must go up LIGHT.
  Future<CreatedShare> createShare({
    required String type,
    required String title,
    required List<Map<String, dynamic>> items,
    String? shareId,
    String? cardPngBase64,
    String imageField = 'image',
  }) async {
    final snapshots = [
      for (final item in items) {...item},
    ];
    final stripped = <int, String>{};
    for (var i = 0; i < snapshots.length && i < maxItems; i++) {
      final image = snapshots[i][imageField];
      if (image is String && image.startsWith('data:')) {
        snapshots[i][imageField] = '';
        stripped[i] = image;
      }
    }
    final created = CreatedShare.fromJson(
      await _backend.createShare({
        'type': type,
        'title': title,
        'items': snapshots,
        if (shareId != null) 'shareId': shareId,
        if (cardPngBase64 != null) 'cardPngBase64': cardPngBase64,
      }),
    );
    if (stripped.isNotEmpty) {
      final flush = _attachImages(created.shareId, stripped);
      _pendingAttachments.add(flush);
      unawaited(flush);
    }
    onEvent?.call('share_create', {'type': type});
    return created;
  }

  /// Uplink stripped heroes one at a time (they share the uplink with the
  /// card upload; parallel megabyte uploads starve it). Best-effort: a
  /// failed hero degrades to placeholder art on the receiving end, never a
  /// failed share.
  Future<void> _attachImages(String shareId, Map<int, String> images) async {
    if (shareId.isEmpty) return;
    for (final entry in images.entries) {
      try {
        await _backend.attachShareImage(shareId, entry.key, entry.value);
      } catch (_) {}
    }
  }

  /// Await any in-flight background attachments (tests; app shutdown).
  Future<void> flushAttachments() async {
    final pending = List.of(_pendingAttachments);
    _pendingAttachments.clear();
    await Future.wait(pending);
  }

  /// Upload the branded card for an already-created share; the link's
  /// unfurl (og:image) picks it up. Best-effort — the web page falls back
  /// to the item hero when absent.
  Future<void> attachCard(String shareId, String cardPngBase64) async {
    try {
      await _backend.attachShareCard(shareId, cardPngBase64);
    } catch (_) {}
  }

  /// Fetch a share for the receiver preview. Null when the share is gone
  /// (revoked or never existed) — the caller shows the dead-end state.
  Future<ShareView?> getShare(String shareId) async {
    final data = await _backend.getShare(shareId);
    if (data['ok'] != true) return null;
    onEvent?.call('share_open', {'source': 'link'});
    return ShareView.fromJson(Map<String, dynamic>.from(data['share'] as Map));
  }

  /// Fire-and-forget saves counter bump; never load-bearing.
  Future<void> recordSave(String shareId, String type) async {
    onEvent?.call('share_save', {'type': type});
    try {
      await _backend.recordShareSave(shareId);
    } catch (_) {}
  }

  Future<void> revokeShare(String shareId) => _backend.revokeShare(shareId);

  Future<ReferralStatus> referralStatus() async =>
      ReferralStatus.fromJson(await _backend.getReferralStatus());

  /// Redeem an invite code, LOUDLY: throws [ShareBackendException] with the
  /// server's rejection code so manual "Have a code?" entry can explain
  /// (own-code, already-redeemed, not-found, account-too-old). Prefer
  /// [autoRedeem] for codes carried on shares. Returns the invitee's credit.
  Future<int> redeem(String code) async {
    final result = await _backend.redeemReferral(code);
    onEvent?.call('referral_redeem', const {});
    return (result['creditDays'] as num?)?.toInt() ?? 0;
  }

  /// Silently redeem a referral code carried on a share. The server is the
  /// gatekeeper — one per account, no self-redeem, account-age gates — so
  /// rejections are EXPECTED outcomes (an existing user opened a friend's
  /// share), not errors, and stay quiet. Returns the invitee's credit on
  /// success, null on any rejection.
  Future<int?> autoRedeem(String code) async {
    if (code.isEmpty) return null;
    try {
      return await redeem(code);
    } on ShareBackendException {
      return null; // already redeemed / own code / too old: expected, silent
    } catch (e) {
      debugPrint('referral auto-redeem failed (non-fatal): $e');
      return null;
    }
  }

  /// Convert banked credit into a store grant, one chunk per call. Returns
  /// granted days (0 = nothing to claim or a paid sub is active and the
  /// credit stays banked).
  Future<int> claimCredit() async {
    final granted = await _backend.claimEntitlementCredit();
    if (granted > 0) onEvent?.call('reward_grant', {'days': granted});
    return granted;
  }
}
