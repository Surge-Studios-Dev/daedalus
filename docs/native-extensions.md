# Native extension targets (widgets, etc.) - the gotchas

Adding an app extension (Ember's WidgetKit widget was the first) is a
~3-minute human step in Xcode plus four traps, each of which cost real
time once. The CLI cannot add extension targets safely; don't try.

1. **Delete the template baggage.** Xcode's Widget Extension wizard
   generates a Control Widget + Live Activity (`*Control.swift`,
   `*LiveActivity.swift`) that require iOS 18, plus a `@main` bundle that
   collides with your widget's `@main`. Remove all generated sources and
   drop your real file into the target folder (Xcode 16 targets are
   folder-synced: files on disk = files in target).
2. **"Cycle inside Runner."** Xcode appends "Embed Foundation Extensions"
   AFTER Flutter's "Thin Binary" script phase. Reorder it before Thin
   Binary in the Runner target's buildPhases (pbxproj edit or drag in
   Xcode) or every build fails with a dependency cycle.
3. **App Groups on BOTH targets**, same id (`group.<bundle-id>`), and the
   Flutter side (home_widget) must use the identical string.
4. **Keep a payload contract test.** The JSON the Flutter bridge writes
   is decoded by Swift; a Dart-side test locking the keys is the only
   tripwire that fails before the widget silently renders blanks.

Reference implementation: Ember (`ios/Ember/EmberWidget.swift`,
`lib/features/widget/widget_bridge.dart`, `WIDGET.md`).
