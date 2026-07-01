import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'error_reporter.dart';

/// The real [ErrorReporter], backed by Firebase Crashlytics. Selected in
/// bootstrap under useFirebase.
class CrashlyticsErrorReporter implements ErrorReporter {
  final _crashlytics = FirebaseCrashlytics.instance;

  @override
  void recordError(Object error, StackTrace? stack, {bool fatal = false}) =>
      _crashlytics.recordError(error, stack, fatal: fatal);
}
