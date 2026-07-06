import 'dart:convert';

/// Persistence seam for [ShareInbox]. The app binds a SharedPreferences
/// store in bootstrap; tests use [InMemoryInboxStore].
abstract class InboxStore {
  Future<List<String>?> readList(String key);
  Future<void> writeList(String key, List<String> value);
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
}

/// In-memory [InboxStore] for tests and fresh stamps.
class InMemoryInboxStore implements InboxStore {
  final Map<String, List<String>> lists = {};
  final Map<String, String> strings = {};

  @override
  Future<List<String>?> readList(String key) async => lists[key];

  @override
  Future<void> writeList(String key, List<String> value) async {
    lists[key] = List.of(value);
  }

  @override
  Future<String?> readString(String key) async => strings[key];

  @override
  Future<void> writeString(String key, String value) async {
    strings[key] = value;
  }
}

/// Durable inbox for shared/queued intake payloads: an app kill mid-work
/// resumes from the queue. Entries leave only when their job reaches a
/// state the user has seen through: saved, discarded, cancelled, or a
/// failure they dismissed.
///
/// A cold start replays any entry still queued (that resilience is the
/// point), so per-entry metadata records whether a meter unit was already
/// charged for it and how many times it has failed — otherwise a replay
/// double-charges the meter, and a permanently-failing share retries
/// forever on every launch.
class ShareInbox {
  ShareInbox(this._store, {this.keyPrefix = 'intake.inbox'});

  final InboxStore _store;

  /// Store key prefix — give each inbox in an app its own prefix.
  final String keyPrefix;

  String get _key => keyPrefix;
  String get _metaKey => '$keyPrefix.meta';

  Future<List<String>> all() async =>
      await _store.readList(_key) ?? const [];

  /// Append [value] unless it is already queued (a re-share keeps its
  /// original position; drain freshness comes from the platform queue).
  Future<void> add(String value) async {
    final list = await _store.readList(_key) ?? <String>[];
    if (!list.contains(value)) {
      list.add(value);
      await _store.writeList(_key, list);
    }
  }

  Future<void> remove(String value) async {
    final list = await _store.readList(_key) ?? <String>[];
    list.remove(value);
    await _store.writeList(_key, list);
    final meta = await _readMeta();
    if (meta.remove(value) != null) {
      await _store.writeString(_metaKey, jsonEncode(meta));
    }
  }

  /// Whether a meter unit was already charged for [value], so a cold-start
  /// replay of the still-queued entry doesn't charge it again.
  Future<bool> isMetered(String value) async {
    final meta = await _readMeta();
    return ((meta[value] as Map?)?['m'] as bool?) ?? false;
  }

  Future<void> markMetered(String value) async {
    final meta = await _readMeta();
    final entry = Map<String, dynamic>.from(meta[value] as Map? ?? const {});
    entry['m'] = true;
    meta[value] = entry;
    await _store.writeString(_metaKey, jsonEncode(meta));
  }

  /// Record a failed attempt for [value] and return the running total, so
  /// the caller can drop a share that keeps failing across launches instead
  /// of retrying it forever.
  Future<int> bumpFailures(String value) async {
    final meta = await _readMeta();
    final entry = Map<String, dynamic>.from(meta[value] as Map? ?? const {});
    final next = ((entry['f'] as int?) ?? 0) + 1;
    entry['f'] = next;
    meta[value] = entry;
    await _store.writeString(_metaKey, jsonEncode(meta));
    return next;
  }

  Future<Map<String, dynamic>> _readMeta() async {
    final raw = await _store.readString(_metaKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}
