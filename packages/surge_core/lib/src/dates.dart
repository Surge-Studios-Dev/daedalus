/// Date helpers, extracted from Ladle. Pure string/ISO based; "today" is
/// always injected so the logic stays testable and timezone-honest (week
/// boundaries follow the device's local calendar, never UTC).
///
/// The whole module works on plain `YYYY-MM-DD` strings and does calendar
/// arithmetic through [DateTime]'s date constructor, never `Duration.inDays`:
/// a spring-forward day is 23 wall-clock hours, and `Duration.inDays`
/// truncates that to 0, silently collapsing week math once a year.
library;

const _dow = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _dowFull = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
const _mon = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime parseIso(String iso) {
  // Keep only the calendar-date portion. Callers store plain "YYYY-MM-DD",
  // but tolerate a full ISO datetime ("2026-06-18T11:56:20") so a stray
  // timestamp in old data doesn't crash here.
  final datePart = iso.split('T').first.split(' ').first;
  final parts = datePart.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

String toIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Calendar-day addition via DateTime so DST weeks still span 7 dates.
String addDays(String iso, int n) {
  final d = parseIso(iso);
  return toIso(DateTime(d.year, d.month, d.day + n));
}

List<String> weekDays(String weekStartIso) =>
    List.generate(7, (i) => addDays(weekStartIso, i));

String fmtDayShort(String iso) {
  final d = parseIso(iso);
  return '${_mon[d.month - 1]} ${d.day}';
}

String fmtDow(String iso) => _dow[parseIso(iso).weekday % 7];

String fmtDowFull(String iso) => _dowFull[parseIso(iso).weekday % 7];

bool isToday(String iso, {required String today}) => iso == today;

bool isPast(String iso, {required String today}) => iso.compareTo(today) < 0;

/// "Jun 8–14" or "Jun 29–Jul 5" across months.
String fmtWeekRange(String weekStart) {
  final days = weekDays(weekStart);
  final a = parseIso(days.first);
  final b = parseIso(days.last);
  final aS = '${_mon[a.month - 1]} ${a.day}';
  final bS = a.month == b.month ? '${b.day}' : '${_mon[b.month - 1]} ${b.day}';
  return '$aS–$bS';
}

/// "This week" / "Next week" / "Last week" relative to [currentWeekStart],
/// otherwise the formatted range.
String weekLabel(String weekStart, {required String currentWeekStart}) {
  if (weekStart == currentWeekStart) return 'This week';
  if (weekStart == addDays(currentWeekStart, 7)) return 'Next week';
  if (weekStart == addDays(currentWeekStart, -7)) return 'Last week';
  return fmtWeekRange(weekStart);
}

/// "Today" / "Yesterday" / "3 days ago" / "May 20".
String fmtRelDate(String? iso, {required String today}) {
  if (iso == null || iso.isEmpty) return '';
  // Count calendar days by stepping the date forward via addDays (the
  // module's DST-safe convention) rather than Duration.inDays, which
  // truncates wall-clock hours and floors a 23h spring-forward gap to 0.
  if (iso == today) return 'Today';
  if (iso.compareTo(today) < 0) {
    var diff = 1;
    while (diff < 7) {
      if (addDays(iso, diff) == today) break;
      diff++;
    }
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
  }
  final d = parseIso(iso);
  return '${_mon[d.month - 1]} ${d.day}';
}

/// Start of the week containing [iso] given the user's week-start setting
/// ("Mon" or "Sun").
String weekStartOf(String iso, {String weekStartsOn = 'Mon'}) {
  final d = parseIso(iso);
  final targetWeekday = weekStartsOn == 'Sun'
      ? DateTime.sunday
      : DateTime.monday;
  var delta = d.weekday - targetWeekday;
  if (delta < 0) delta += 7;
  return addDays(iso, -delta);
}

/// Every week-doc key that could store one of [days], for data persisted in
/// docs keyed by week start while the week-start setting is user-togglable.
///
/// A row lands in the doc keyed by the week start that was active when it
/// was written, and only two week starts exist (Mon/Sun), so each calendar
/// day maps to at most two candidate docs. Readers and writers both go
/// through this so they agree on which docs hold a visible week's rows,
/// independent of the user's current setting (a Sun↔Mon toggle shifts a
/// day's doc key by 1–6 days, so keying off a single "current" week would
/// orphan rows in the off-alignment doc). Returns keys in deterministic
/// insertion order.
List<String> weekDocKeysFor(Iterable<String> days) {
  final keys = <String>{};
  for (final iso in days) {
    keys.add(weekStartOf(iso, weekStartsOn: 'Mon'));
    keys.add(weekStartOf(iso, weekStartsOn: 'Sun'));
  }
  return keys.toList();
}
