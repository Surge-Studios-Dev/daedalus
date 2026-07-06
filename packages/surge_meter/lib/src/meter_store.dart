/// Persistence seam for [UsageMeter]. The app binds a SharedPreferences
/// store in bootstrap; tests use [InMemoryMeterStore].
///
/// ```dart
/// class PrefsMeterStore implements MeterStore {
///   PrefsMeterStore(this._prefs);
///   final SharedPreferences _prefs;
///   @override
///   Future<String?> read(String key) async => _prefs.getString(key);
///   @override
///   Future<void> write(String key, String value) => _prefs.setString(key, value);
/// }
/// ```
abstract class MeterStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory [MeterStore] for tests and fresh stamps. [readDelay] lets a
/// test reproduce the slow-first-read race the meter guards against.
class InMemoryMeterStore implements MeterStore {
  InMemoryMeterStore({this.readDelay = Duration.zero});

  final Duration readDelay;
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async {
    if (readDelay > Duration.zero) {
      await Future<void>.delayed(readDelay);
    }
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
