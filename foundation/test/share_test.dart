import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surge_foundation/modules/share/invite_card.dart';
import 'package:surge_foundation/modules/share/share.dart';
import 'package:surge_share/surge_share.dart';
import 'package:surge_ui/surge_ui.dart';

/// The growth rail's foundation surface (SET-03/SET-04): invite card,
/// manual code redemption, and the boot-drain of banked credit - all on
/// the mock backend, which enforces the real server rules.
Future<ProviderContainer> _pumpCard(
  WidgetTester tester,
  MockShareBackend backend,
) async {
  final container = ProviderContainer(
    overrides: [shareBackendProvider.overrideWithValue(backend)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSurgeTheme(Brightness.light),
        home: const Scaffold(body: SingleChildScrollView(child: InviteCard())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('invite card shows the code and copies the invite link', (
    tester,
  ) async {
    final backend = MockShareBackend(uid: 'me');
    await _pumpCard(tester, backend);

    expect(find.text('Invite a friend'), findsOneWidget);
    expect(find.text('code-me'), findsOneWidget);

    // Capture the platform clipboard call.
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    await tester.tap(find.text('Copy invite link'));
    await tester.pumpAndSettle();
    expect(copied.single, contains('/i/code-me'));
    expect(find.text('Invite link copied'), findsOneWidget);
    // Let the toast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('banked credit drains through the claimer on status load', (
    tester,
  ) async {
    final backend = MockShareBackend(uid: 'me', grantChunkDays: 30);
    backend.referrals['me'] = MockReferral(code: 'code-me')..creditDays = 40;
    await _pumpCard(tester, backend);
    await tester.pump(); // let the listener's claim future run

    // One chunk per claim: 40 banked -> 30 granted, 10 stay banked until
    // the next status emission (boot, redeem, invalidate).
    expect(backend.referrals['me']!.creditDays, 10);
  });

  testWidgets('manual code entry redeems and surfaces server rejections', (
    tester,
  ) async {
    final backend = MockShareBackend(uid: 'me');
    // A friend already has a code in the system.
    backend.referrals['friend'] = MockReferral(code: 'FRIEND-1');
    await _pumpCard(tester, backend);

    await tester.tap(find.text('Have a code?'));
    await tester.pumpAndSettle();
    expect(find.text('Enter invite code'), findsOneWidget);

    // Own code -> friendly rejection, sheet stays open.
    await tester.enterText(find.byType(TextField), 'code-me');
    await tester.tap(find.text('Redeem'));
    await tester.pumpAndSettle();
    expect(
      find.text("That's your own code. Share it with a friend instead."),
      findsOneWidget,
    );

    // The friend's code redeems: toast + sheet closed + card hides the
    // "Have a code?" entry (one redemption per account).
    await tester.enterText(find.byType(TextField), 'FRIEND-1');
    await tester.tap(find.text('Redeem'));
    await tester.pumpAndSettle();
    expect(find.text('Enter invite code'), findsNothing);
    expect(
      find.text('Invite applied. You got 7 free days.'),
      findsOneWidget,
    );
    expect(find.text('Have a code?'), findsNothing);
    expect(backend.referrals['me']!.redeemedCode, isTrue);
    expect(backend.referrals['friend']!.lifetimeReferrals, 1);
    // Let the toast's auto-dismiss timer fire before teardown.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });
}
