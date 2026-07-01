import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The crash/error boundary the app depends on. Default [DebugErrorReporter]
/// prints; `CrashlyticsErrorReporter` sends to Firebase Crashlytics. Bootstrap
/// also routes uncaught framework/isolate errors here when live.
abstract interface class ErrorReporter {
  void recordError(Object error, StackTrace? stack, {bool fatal});
}

class DebugErrorReporter implements ErrorReporter {
  const DebugErrorReporter();

  @override
  void recordError(Object error, StackTrace? stack, {bool fatal = false}) {
    if (kDebugMode) debugPrint('[error${fatal ? ' fatal' : ''}] $error\n$stack');
  }
}

final errorReporterProvider = Provider<ErrorReporter>(
  (ref) => const DebugErrorReporter(),
);
