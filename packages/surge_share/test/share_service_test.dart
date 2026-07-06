import 'package:flutter_test/flutter_test.dart';
import 'package:surge_share/surge_share.dart';

/// Records the exact wire payloads so the choreography (light doc first,
/// heavy artifacts after) is pinned by tests, not folklore.
class RecordingBackend extends MockShareBackend {
  RecordingBackend();

  final createPayloads = <Map<String, dynamic>>[];
  final attachedImages = <(String, int, String)>[];
  bool failAttaches = false;

  @override
  Future<Map<String, dynamic>> createShare(
    Map<String, dynamic> payload,
  ) {
    createPayloads.add(payload);
    return super.createShare(payload);
  }

  @override
  Future<void> attachShareImage(
    String shareId,
    int index,
    String imageDataUri,
  ) async {
    if (failAttaches) throw const ShareBackendException('unavailable');
    attachedImages.add((shareId, index, imageDataUri));
    await super.attachShareImage(shareId, index, imageDataUri);
  }
}

void main() {
  const dataUri = 'data:image/png;base64,aGVsbG8=';

  group('create choreography', () {
    test('the doc goes up light: data heroes stripped, attached after',
        () async {
      final backend = RecordingBackend();
      final service = ShareService(backend);
      final created = await service.createShare(
        type: 'recipe',
        title: 'Pasta',
        shareId: newLocalShareId(),
        items: [
          {'name': 'Pasta', 'image': dataUri},
          {'name': 'Salad', 'image': 'https://cdn/x.jpg'},
        ],
      );

      // The create payload must not carry the inline hero...
      final sentItems = backend.createPayloads.single['items'] as List;
      expect((sentItems[0] as Map)['image'], '');
      // ...but http URLs ride along untouched.
      expect((sentItems[1] as Map)['image'], 'https://cdn/x.jpg');

      await service.flushAttachments();
      expect(backend.attachedImages.single.$1, created.shareId);
      expect(backend.attachedImages.single.$2, 0);
      expect(backend.attachedImages.single.$3, dataUri);
      // The stored share got its hero back.
      expect(backend.shares[created.shareId]!.items[0]['image'], dataUri);
    });

    test('caller-side items are never mutated', () async {
      final backend = RecordingBackend();
      final service = ShareService(backend);
      final items = [
        {'name': 'Pasta', 'image': dataUri},
      ];
      await service.createShare(type: 'recipe', title: 'Pasta', items: items);
      expect(items[0]['image'], dataUri);
    });

    test('a failed attach degrades, never throws', () async {
      final backend = RecordingBackend()..failAttaches = true;
      final service = ShareService(backend);
      await service.createShare(
        type: 'recipe',
        title: 'Pasta',
        items: [
          {'name': 'Pasta', 'image': dataUri},
        ],
      );
      await service.flushAttachments(); // must complete without error
      expect(backend.attachedImages, isEmpty);
    });

    test('a pregenerated id collision is refused, not overwritten', () async {
      final backend = RecordingBackend();
      final service = ShareService(backend);
      final id = newLocalShareId();
      await service.createShare(
        type: 'recipe',
        title: 'First',
        shareId: id,
        items: const [],
      );
      expect(
        () => service.createShare(
          type: 'recipe',
          title: 'Hijack',
          shareId: id,
          items: const [],
        ),
        throwsA(
          isA<ShareBackendException>()
              .having((e) => e.code, 'code', 'already-exists'),
        ),
      );
    });

    test('items past the bundle cap are dropped honestly', () async {
      final backend = RecordingBackend();
      final service = ShareService(backend, maxItems: backend.maxItems);
      final created = await service.createShare(
        type: 'collection',
        title: 'Big',
        items: [
          for (var i = 0; i < 60; i++) {'name': 'item $i'},
        ],
      );
      expect(created.droppedItems, 10);
      expect(backend.shares[created.shareId]!.items.length, 50);
    });
  });

  group('receiver flow', () {
    test('get -> save roundtrip, revoked reads as gone', () async {
      final backend = MockShareBackend();
      final service = ShareService(backend);
      final created = await service.createShare(
        type: 'recipe',
        title: 'Pasta',
        items: [
          {'name': 'Pasta'},
        ],
      );

      final view = await service.getShare(created.shareId);
      expect(view, isNotNull);
      expect(view!.title, 'Pasta');
      expect(view.ref, isNotEmpty); // referral code rides on every share
      expect(view.items.single['name'], 'Pasta');

      await service.recordSave(created.shareId, 'recipe');
      expect(backend.shares[created.shareId]!.saves, 1);

      await service.revokeShare(created.shareId);
      expect(await service.getShare(created.shareId), isNull);
      expect(await service.getShare('never-existed'), isNull);
    });
  });

  group('referrals (money-shaped state)', () {
    test('redeem grants both sides; the server computes rewards', () async {
      final backend = MockShareBackend(uid: 'inviter');
      final inviterStatus =
          await ShareService(backend).referralStatus(); // creates the record

      backend.uid = 'invitee';
      final service = ShareService(backend);
      final granted = await service.autoRedeem(inviterStatus.code);
      expect(granted, backend.rewardPerReferral);

      final invitee = await service.referralStatus();
      expect(invitee.redeemedCode, isTrue);
      expect(invitee.creditDays, backend.rewardPerReferral);

      backend.uid = 'inviter';
      final inviter = await ShareService(backend).referralStatus();
      expect(inviter.lifetimeReferrals, 1);
      expect(inviter.creditDays, backend.rewardPerReferral);
    });

    test('redeem() is loud: manual entry gets the rejection code', () async {
      final backend = MockShareBackend(uid: 'me');
      final service = ShareService(backend);
      final myCode = (await service.referralStatus()).code;
      expect(
        () => service.redeem(myCode),
        throwsA(
          isA<ShareBackendException>()
              .having((e) => e.code, 'code', 'own-code'),
        ),
      );
    });

    test(
        'expected rejections are silent nulls: own code, double redeem, unknown',
        () async {
      final backend = MockShareBackend(uid: 'inviter');
      final service = ShareService(backend);
      final me = await service.referralStatus();

      expect(await service.autoRedeem(me.code), isNull); // no self-redeem
      expect(await service.autoRedeem('nope'), isNull); // unknown code

      backend.uid = 'invitee';
      expect(await service.autoRedeem(me.code), isNotNull);
      expect(await service.autoRedeem(me.code), isNull); // one per account
    });

    test('the reward cap is enforced lifetime, server-side', () async {
      final backend = MockShareBackend(
        uid: 'inviter',
        rewardPerReferral: 7,
        rewardCap: 10,
      );
      final inviterCode = (await ShareService(backend).referralStatus()).code;
      for (final friend in ['a', 'b', 'c']) {
        backend.uid = friend;
        await ShareService(backend).autoRedeem(inviterCode);
      }
      backend.uid = 'inviter';
      final inviter = await ShareService(backend).referralStatus();
      expect(inviter.lifetimeReferrals, 3);
      expect(inviter.creditDays, 10); // 7 + 3(capped) + 0
    });

    test('claims drain one chunk per call and refuse while entitled', () async {
      final backend = MockShareBackend(uid: 'u', grantChunkDays: 30);
      backend.referrals['u'] = MockReferral(code: 'code-u')..creditDays = 70;
      final service = ShareService(backend);

      backend.entitled = true;
      expect(await service.claimCredit(), 0); // banked as lapse credit

      backend.entitled = false;
      expect(await service.claimCredit(), 30);
      expect(await service.claimCredit(), 30);
      expect(await service.claimCredit(), 10);
      expect(await service.claimCredit(), 0); // bank drained
    });
  });

  group('CreditClaimer guards', () {
    test('claims once per balance, retries on a new balance', () async {
      var claims = 0;
      final granted = <int>[];
      final claimer = CreditClaimer(
        claim: () async {
          claims++;
          return 7;
        },
        onGranted: granted.add,
      );

      await claimer.notify(0); // nothing banked -> no claim
      await claimer.notify(7);
      await claimer.notify(7); // same balance -> no re-claim loop
      expect(claims, 1);
      expect(granted, [7]);

      await claimer.notify(14); // balance moved -> claim again
      expect(claims, 2);
    });

    test('a throwing claim is swallowed and retried on the next balance',
        () async {
      var calls = 0;
      final claimer = CreditClaimer(
        claim: () async {
          calls++;
          throw StateError('store key unconfigured');
        },
      );
      await claimer.notify(7); // must not throw
      await claimer.notify(14);
      expect(calls, 2);
    });
  });

  group('telemetry hook', () {
    test('standard events fire with their props', () async {
      final events = <String>[];
      final backend = MockShareBackend(uid: 'inviter');
      final inviterCode = (await ShareService(backend).referralStatus()).code;

      backend.uid = 'u2';
      final service = ShareService(
        backend,
        onEvent: (event, props) => events.add(event),
      );
      final created = await service.createShare(
        type: 'recipe',
        title: 'T',
        items: const [],
      );
      await service.getShare(created.shareId);
      await service.recordSave(created.shareId, 'recipe');
      await service.autoRedeem(inviterCode);
      backend.referrals['u2']!.creditDays = 7;
      await service.claimCredit();

      expect(events, [
        'share_create',
        'share_open',
        'share_save',
        'referral_redeem',
        'reward_grant',
      ]);
    });
  });
}
